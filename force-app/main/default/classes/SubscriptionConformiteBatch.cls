/**
 * @name : SubscriptionConformiteBatch
 * @description : Batch to check compliance of subscription based on the subscription's compliance.
 * @author : WR
 * @date : 26/06/2021
 *
 */

global class SubscriptionComplianceCheck implements Database.Batchablae<sObject> {
    private static final String ELEMENTS_MANQUANTS =  Label.Subsciption_Status_ElementsManquants //Éléments manquants'; //La bonne pratique est de passer par des étiquettes personnalisées 
    //La bonne pratique est de passer par des étiquettes personnalisées ou nous mettions la valeur "Conformité Immo neuf"
    private static final String COMPLIANCE_IMMO_NEUF =  Label.Conformite_ImmoNeuf;  
    //La bonne pratique est de passer par des étiquettes personnalisées ou nous mettions la valeur "Conformité Pub"
    private static final String COMPLIANCE_PUB =  Label.Conformite_Pub;  
    //Dans le cas ou on ajoute des nouveaux conformités, il faut les ajouter dans la liste.
    private static final set<String> setAllComplianceProcesses = new set<String>{COMPLIANCE_IMMO_NEUF, COMPLIANCE_PUB};

    
    
    global List<SBQQ__Subscription__c> start(Database.BatchableContext cnx) { 

         String query = 'SELECT Id, CompanyAddressCity__c, OrderNumber__c, CompanyAddressCountry__c, CompanyPhone__c, ContactGender__c, ContactLastName__c,';
        query += 'ContactFirstName__c, Companyindustry__c, CompanyName__c, PrintVolume__c, BroadcastSoftware__c, PromoterDescription__c, SBQQ__RequiredById__c,';
        query += 'FlowType__c, BroadcastPartner__c, PostalCode__c, Souscription_Conforme__c, ComplianceProcess__c, Status__c, AccessStoreState__c,';
        query += 'ProductWorkflow__c, AccessUserId__c, KilometerRadius__c, AccessStoreId__c, CompanyAddressStreet__c, CompanyAddressZipcode__c, LeadPhone__c,';
        query += 'ContractEmail__c, CompanySegment__c, CompanySiret__c FROM SBQQ__Subscription__c ';
        query += 'WHERE Status__c = :ELEMENTS_MANQUANTS AND Souscription_Conforme__c = false';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext cnx, List<SBQQ__Subscription__c> scope) {

        try {
          
            List<SBQQ__Subscription__c> listSubCompliance = new List<SBQQ__Subscription__c>();
            Set<Id> setParentIds = new Set<Id>();

            for(SBQQ__Subscription__c sub : scope) {
                if(sub.ComplianceProcess__c!=null && setAllComplianceProcesses.contains(sub.ComplianceProcess__c)) {
                String compliance= sub.ComplianceProcess__c;

                //nous pourrons ajouter des nouvelles methodes dans la même classe et des nouveaux "when" dans le switch
                switch on compliance {

                    //si cnformité = immo neuf
                    when COMPLIANCE_IMMO_NEUF{
                        sub = setConformiteImmoNeuf(sub);
                    }
                    //si conformité = conformité but
                    when COMPLIANCE_PUB{
                        sub = setConformiteBUT(sub);
                    }

                listUpdatedSubs.add(sub);
            }

            if(listUpdatedSubs!=null&&listUpdatedSubs.size()>0) 
            {
                    update listUpdatedSubs;

                    for(SBQQ__Subscription__c updatedSub:listUpdatedSubs)
                    {
                        //Pour optimiser, j'ajoute les SBQQ__RequiredById__c dans un set
                        if (updatedSub.SBQQ__RequiredById__c != null && updatedSub.Souscription_Conforme__c) {
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
     * @param : SBQQ__Subscription__c
     * @return : SBQQ__Subscription__c
     * @description : update subscription conforme if the conditions are met for "immo neuf" compliance
     * @Throws [Exceptions]: [optional]                                                          
     */
    // méthode modifié pour bulkifier
    private SBQQ__Subscription__c setConformiteImmoNeuf(SBQQ__Subscription__c sub) {

            if(sub.PromoterDescription__c != null && sub.FlowType__c != null && sub.ProductWorkflow__c != null
                && sub.ContractEmail__c != null && sub.CompanySiret__c != null && sub.CompanyName__c != null
                && sub.CompanyAddressStreet__c != null && sub.CompanyAddressZipcode__c != null && sub.CompanyAddressCity__c != null
                && sub.CompanyPhone__c != null && sub.ContactGender__c != null && sub.ContactFirstName__c != null 
                && sub.ContactLastName__c != null && sub.LeadPhone__c != null) {

              sub.Souscription_Conforme__c = true;
            }
            } else {
                //nous pouvons faire autrement, en créant un "field set" sur la platform, et faire un loop sur cette dernière afin d'avoir moins de ligne
                sub.MissingInformations__c += sub.PromoterDescription__c == null ? 'PromoterDescription__c - ' : '';
                sub.MissingInformations__c += sub.FlowType__c == null ? 'FlowType__c - ' : '';
                sub.MissingInformations__c += sub.ProductWorkflow__c == null ? 'ProductWorkflow__c - ' : '';
                sub.MissingInformations__c += sub.ContractEmail__c == null ? 'ContractEmail__c - ' : '';
                sub.MissingInformations__c += sub.CompanySiret__c == null ? 'CompanySiret__c - ' : '';
                sub.MissingInformations__c += sub.CompanyName__c == null ? 'CompanyName__c - ' : '';
                sub.MissingInformations__c += sub.CompanyAddressStreet__c == null ? 'CompanyAddressStreet__c - ' : '';
                sub.MissingInformations__c += sub.CompanyAddressZipcode__c == null ? 'CompanyAddressZipcode__c - ' : '';
                sub.MissingInformations__c += sub.CompanyAddressCity__c == null ? 'CompanyAddressCity__c - ' : '';
                sub.MissingInformations__c += sub.CompanyPhone__c == null ? 'CompanyPhone__c - ' : '';
                sub.MissingInformations__c += sub.ContactGender__c == null ? 'ContactGender__c - ' : '';
                sub.MissingInformations__c += sub.ContactFirstName__c == null ? 'ContactFirstName__c -' : '';
                sub.MissingInformations__c += sub.ContactLastName__c == null ? 'ContactLastName__c - ' : '';
                sub.MissingInformations__c += sub.LeadPhone__c == null ? 'LeadPhone__c ' : '';
		    }

            return sub;
        
    }
     /**
     * @param : SBQQ__Subscription__c
     * @return : SBQQ__Subscription__c
     * @description : update subscription conforme if the conditions are met for "but" compliance
     * @Throws [Exceptions]: [optional]                                                          
     */
    private SBQQ__Subscription__c setConformiteBUT(SBQQ__Subscription__c sub) {

            if(sub.EffectiveEndDate__c != null && sub.EffectiveEndDate__c > Date.today()) {
		            sub.Souscription_Conforme__c = true;
		    } else {
		        	sub.MissingInformations__c += ' EffectiveEndDate__c ';
		    }

            return sub;
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
        
        List<SBQQ__Subscription__c> parentsToUpdate = new List<SBQQ__Subscription__c>(); // 

        List<SBQQ__Subscription__c> listParentSub = [SELECT Id, Souscription_Conforme__c FROM SBQQ__Subscription__c WHERE Status__c = :ELEMENTS_MANQUANTS 
                                           AND Souscription_Conforme__c = false AND Id in :parentIdSet];
        if (listParentSub!=null&& listParentSub.size() > 0) { //il faut chequer si c'est null, sinon on risque d'avoir un null exception si le résultat retourné est null
            for(SBQQ__Subscription__c parentsub:listParentSub)
                parentSub.Souscription_Conforme__c = true;
                parentsToUpdate.add(parentsub)
        }
        if(parentsToUpdate.size()>0)
        {
            //nous pouvons utiliser Database.update si nous souhaitons upater malgrès les erreurs.
            update parentsToUpdate; 
        }

    }
}
