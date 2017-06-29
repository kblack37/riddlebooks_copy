package wordproblem.account;


import cgs.server.IntegrationDataService;
import cgs.server.responses.CgsUserResponse;
import cgs.server.responses.ResponseStatus;

import wordproblem.log.AlgebraAdventureLogger;

/**
 * Used to authenticate or create accounts that will link an external id (i.e. the id a user
 * is assigned in a third party web site like edmodo and brainpop) with an account on cgs.
 * The cgs account is necessary to fetch the correct save data as well as make the user id
 * consistent in the play logs if the user has several different sessions.
 */
class ExternalIdAuthenticator
{
    /**
     * Reference to the logger is needed to handle logic related to creating cgs account
     * based on
     */
    private var m_logger : AlgebraAdventureLogger;
    
    /**
     * Huge hack:
     * All users are treated as 'students' belonging to a teacher. In this case the teacher would encompass all
     * the players of the brainpop version of the game. The student account needs an extra code that bounds it to this
     * global teacher.
     */
    private var m_dummyTeacherCode : String;
    private var m_saveToServer : Bool;
    private var m_noSqlSaveKey : String;
    
    /**
     * This service is need to check if the user has a link between the brainpop id and a cgs account
     */
    private var m_integrationDataService : IntegrationDataService;
    private var m_integrationServiceSuccessCallback : Function;
    private var m_integrationServiceFailCallback : Function;
    private var m_savedExternalId : String;
    
    public function new(logger : AlgebraAdventureLogger,
            dummyTeacherCode : String,
            saveToServer : Bool,
            noSqlSaveKey : String,
            useHttps : Bool)
    {
        m_logger = logger;
        m_dummyTeacherCode = dummyTeacherCode;
        m_saveToServer = saveToServer;
        m_noSqlSaveKey = noSqlSaveKey;
        m_integrationDataService = logger.getCgsApi().createIntegrationDataService(m_logger.getCgsUserProperties(false, null));
    }
    
    /**
     * Attempt to check if a given external id matches a cgs account, if so then authenticate
     * the user. If not we should try creating an account
     * We need to use this to bind it to cgs credentials, which will help us keep track
     * of logging data and save data on our side.
     * 
     * @param externalId
     *      Id provided by a third party site
     * @param externalSource
     *      Numeric id
     * @param successCallback
     *      Triggered if we could successfully link the given brainpopId to a cgs account
     * @param failCallback
     *      Triggered if we could not link the brainpopId to a cgs account
     */
    public function authenticateWithExternalId(externalId : String,
            externalSource : Int,
            successCallback : Function,
            failCallback : Function) : Void
    {
        m_savedExternalId = externalId;
        m_integrationServiceSuccessCallback = successCallback;
        m_integrationServiceFailCallback = failCallback;
        
        // Using just the brainpop id, figure out is a cgs account already exists
        // To differentiate between the two situations we just need to check if the
        // currently assigned uid has an account associated with it
        // (Brainpop should have its own special teacher code)
        m_integrationDataService.checkStudentNameAvailable(
                m_savedExternalId,
                null,
                m_dummyTeacherCode,
                function(responseStatus : ResponseStatus) : Void
                {
                    // No account is present we need to create a new student AND link it to the brainpop id
                    // via the external_ref tables
                    if (responseStatus.success) 
                    {
                        // HACK: The fake grade must be greater than 2 to force the TOS to show up if such a document is required
                        m_logger.getCgsApi().registerStudent(
                                m_logger.getCgsUserProperties(m_saveToServer, m_noSqlSaveKey), m_savedExternalId, m_dummyTeacherCode, 4,
                                function(response : CgsUserResponse) : Void
                                {
                                    if (response.success && response.cgsUser) 
                                    {
                                        // Create a link from the registered user (need to get the cgs id)
                                        // and the external id for data analysis purposes
                                        var newUserId : String = response.cgsUser.userId;
                                        m_integrationDataService.updateExternalIdAndSourceFromUserId(newUserId, m_savedExternalId, externalSource, null);
                                        
                                        if (m_integrationServiceSuccessCallback != null) 
                                        {
                                            m_integrationServiceSuccessCallback();
                                        }
                                    }
                                    else 
                                    {
                                        if (m_integrationServiceFailCallback != null) 
                                        {
                                            m_integrationServiceFailCallback();
                                        }
                                    }
                                }, 0);
                    }
                    // Some account with that username is present, this means we should be able to authenticate this
                    // brainpop user.
                    else 
                    {
                        m_logger.getCgsApi().authenticateStudent(
                                m_logger.getCgsUserProperties(true, null),
                                m_savedExternalId,
                                m_dummyTeacherCode,
                                null,
                                0,
                                function onAuthenticate(response : CgsUserResponse) : Void
                                {
                                    if (response.success) 
                                    {
                                        var cgsUserId : String = response.cgsUser.userId;
                                        
                                        // Need to make sure the link between the brainpop id and the cgs id has
                                        // been established
                                        m_integrationDataService.getUserIdFromExternalIdAndSource(
                                                m_savedExternalId,
                                                externalSource,
                                                function(response : ResponseStatus, uid : String) : Void
                                                {
                                                    if (uid != cgsUserId) 
                                                    {
                                                        m_integrationDataService.updateExternalIdAndSourceFromUserId(cgsUserId, m_savedExternalId, externalSource, null);
                                                    }
                                                    else 
                                                    {
                                                        // Link already established do not need to do anything else
                                                        
                                                    }
                                                });
                                        
                                        if (m_integrationServiceSuccessCallback != null) 
                                        {
                                            m_integrationServiceSuccessCallback();
                                        }
                                    }
                                    else 
                                    {
                                        // Is there any error handling to do here if authentication fails?
                                        if (m_integrationServiceFailCallback != null) 
                                        {
                                            m_integrationServiceFailCallback();
                                        }
                                    }
                                }
                                );
                    }
                }
                );
    }
}
