/**
 * @name : SubscriptionComplianceCheck
 * @description : Batch to check compliance of subscription.
 * @author : WR
 * @date : 26/06/2021
 *
 */

global class SubscriptionComplianceCheck implements Database.Batchablae<sObject> {
    private static final String ELEMENTS_MANQUANTS =  Label.Subsciption_Status_ElementsManquants //Éléments manquants'; //La bonne pratique est de passer par des étiquettes personnalisées 
    private static final String IMMO_NEUF =  Label.Subscription_Status_ConformiteImmoNeufConformité; /La bonne pratique est de passer par des étiquettes personnalisées 
    
    
    global List<SBQQ__Subscription__c> start(Database.BatchableContext cnx) { 

         String query = 'SELECT Id, CompanyAddressCity__c, OrderNumber__c, CompanyAddressCountry__c, CompanyPhone__c, ContactGender__c, ContactLastName__c,';
        query += 'ContactFirstName__c, Companyindustry__c, CompanyName__c, PrintVolume__c, BroadcastSoftware__c, PromoterDescription__c, SBQQ__RequiredById__c,';
        query += 'FlowType__c, BroadcastPartner__c, PostalCode__c, Souscription_Conforme__c, ComplianceProcess__c, Status__c, AccessStoreState__c,';
        query += 'ProductWorkflow__c, AccessUserId__c, KilometerRadius__c, AccessStoreId__c, CompanyAddressStreet__c, CompanyAddressZipcode__c, LeadPhone__c,';
        query += 'ContractEmail__c, CompanySegment__c, CompanySiret__c, MissingInformations__c, EffectiveEndDate__c FROM SBQQ__Subscription__c ';
        query += 'WHERE Status__c = :ELEMENTS_MANQUANTS AND Souscription_Conforme__c = false';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext cnx, List<SBQQ__Subscription__c> scope) {

        try {
          
            List<SBQQ__Subscription__c> listSubCompliance = new List<SBQQ__Subscription__c>();
            Set<Id> setParentIds = new Set<Id>();

            for(SBQQ__Subscription__c sub : scope) {
                if(sub.ComplianceProcess__c == IMMO_NEUF) {
                   listSubCompliance.add(sub);
            }
            if(listSubCompliance.size()>0)
            {
                // traiter la liste complète en bulk pour une optimisation
                List<SBQQ__Subscription__c> listUpdatedSubs = setConformiteImmoNeuf(listSubCompliance); 

                if(listUpdatedSubs!=null&&listUpdatedSubs.size()>0) 
                {
                    for(SBQQ__Subscription__c updatedSub:listUpdatedSubs)
                    {
                        //Pour optimiser, j'ajoute les SBQQ__RequiredById__c dans un set
                        if (updatedSub.SBQQ__RequiredById__c != null) {
                            setParentIds.add(updatedSub.SBQQ__RequiredById__c);                        
                    }
                    if(setParentIds.size>0)
                    {
                        // pour optimiser, j'envoie un set de tous les parents Ids et je traite en bulk
                        setParentConforme(setParentIds); 
                    }
                    
                }
            }
                
            
        } catch(Exception e) { // la bonne pratique et de passer par une customException
            Logs.error('SubscriptionComplianceCheck','Batch Compliance Check', e);
        }
    }
    
    global void finish(Database.BatchableContext cnx) {
        // nous pouvons envoyer un email à la complétion
    }
    
     /**
     * @param : List<SBQQ__Subscription__c>
     * @return : List<SBQQ__Subscription__c>
     * @description : update subscription conforme if the conditions are met
     * @Throws [Exceptions]: [optional]                                                          
     */
    // méthode modifié pour bulkifier
    private List<SBQQ__Subscription__c> setConformiteImmoNeuf(List<SBQQ__Subscription__c> listSubs) {

        List<SBQQ__Subscription__c> listSubsToUpdate = new List<SBQQ__Subscription__c>();

        for(SBQQ__Subscription__c sub:listSubs)
        {
            if(sub.PromoterDescription__c != null && sub.FlowType__c != null && sub.ProductWorkflow__c != null
          && sub.ContractEmail__c != null && sub.CompanySiret__c != null && sub.CompanyName__c != null
          && sub.CompanyAddressStreet__c != null && sub.CompanyAddressZipcode__c != null && sub.CompanyAddressCity__c != null
          && sub.CompanyPhone__c != null && sub.ContactGender__c != null && sub.ContactFirstName__c != null 
          && sub.ContactLastName__c != null && sub.LeadPhone__c != null) {

              listSubsToUpdate.add(sub);
            }

            if(listSubsToUpdate.size()>0)
            {
                for(SBQQ__Subscription__c subToUpdate:listSubsToUpdate)
                {
                    subToUpdate.Souscription_Conforme__c = true;
                }
                //nous pouvons utiliser Database.update si nous souhaitons upater malgrès les erreurs.
                update subToUpdate; // mettre à jour les souscriptions conformes
            }
            

            return listSubsToUpdate;// retourner la liste mise à jour
        
        }
        
    }
     /**
     * @param : String 
     * @return : void 
     * @description : update the parents subscriptions when the children are updated
     * @Throws [Exceptions]: Exception                                                         
     */
    // méthode modifié pour bulkifier
    private void setParentConforme(Set<String> parentIdSet) {
        
        List<SBQQ__Subscription__c> listParentsToUpdate = new List<SBQQ__Subscription__c>(); // 

        List<SBQQ__Subscription__c> listParentSub = [SELECT Id, Souscription_Conforme__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS 
                                           AND Souscription_Conforme__c = false AND Id in :parentIdSet];
        if (listParentSub!=null&& listParentSub.size() > 0) { //il faut chequer si c'est null, sinon on risque d'avoir un null exception si le résultat retourné est null
            for(SBQQ__Subscription__c parentsub:listParentSub)
                parentSub.Souscription_Conforme__c = true;
                listParentsToUpdate.add(parentsub)
        }
        if(listParentsToUpdate.size()>0)
        {
            //nous pouvons utiliser Database.update si nous souhaitons upater malgrès les erreurs.
            update listParentsToUpdate; 
        }

    }
}
