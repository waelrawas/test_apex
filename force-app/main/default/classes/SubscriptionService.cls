/**
 * @name : SubscriptionService
 * @description : Service class for the Subscription Object to use for triggers
 * @author : WR
 * @date : 26/06/2021
 *
 */
public class SubscriptionService{

    /**
     * @param : List<SBQQ__Subscription__c>
     * @return : void
     * @description : update contract end of date based on subscriptions
     * @Throws [Exceptions]: ..                                                  
     */
    public static void updateConEndDate(List<SBQQ__Subscription__c> listSubsTriggerNew)
     
    Boolean isTerminate;
    Date terminatedDate;
    Date endDate;
    Date oldDate;
    // nous avons pas besoin de requêter à ce point, les infos existent dans le trigger.new
    //List<SBQQ__Subscription__c> sub=[SELECT SBQQ__Contract__c,TechAmendmentReason__c FROM SBQQ__Subscription__c where id =:Trigger.new];     

    Set<Id> cons = new Set<Id>();
    for (SBQQ__Subscription__c sub :listSubsTriggerNew) {
        
        if(sub.SBQQ__Contract__c!=null)
        {
            cons.add(sub.SBQQ__Contract__c);
        }
       
    }
    try {
        List<Contract> conts = new List<Contract>();
        for (Contract con : [SELECT Id, EndDate, (SELECT Id, SBQQ__EndDate__c, SBQQ__TerminatedDate__c, SBQQ__Contract__c 
                                              FROM SBQQ__Subscriptions__r) FROM Contract WHERE Id IN :cons]) {
                                                  system.debug('SubscriptionService/updateConEndDate : contrat on :: '+con)   ; 
            isTerminate = true;
            terminatedDate = con.EndDate;
            endDate = con.EndDate;
            oldDate = con.EndDate;//garder la valeur initiale pour comparer à la fin du traitement
              
            for (SBQQ__Subscription__c sub : con.SBQQ__Subscriptions__r) {
                if (sub.SBQQ__TerminatedDate__c == null) {
                    isTerminate = false;
                } else if (terminatedDate < sub.SBQQ__TerminatedDate__c) {
                    terminatedDate = sub.SBQQ__TerminatedDate__c;
                }
                if (sub.SBQQ__EndDate__c != null && endDate < sub.SBQQ__EndDate__c) {
                    endDate = sub.SBQQ__EndDate__c;
                }
            }
            
            if (isTerminate) {
                con.EndDate = terminatedDate;
            } else {
                con.EndDate = endDate;
            }
                                            
            if(oldDate!=con.EndDate){
                conts.add(con); //pour optimiser, on met à jour que celles qui ont été modifié
            }                                  
            
        }
        
        if(conts.size()>0)
        {
            UPDATE conts;//nous pouvons utiliser Database.update si nous souhaitons upater malgrès les erreurs.
        }
        
       
        
    } catch(Exception e) {
            Logs.error('ContractEndDateAdapterTrigger','SBQQ__Subscription__c Trigger insert & update', e);
    }
    
}
