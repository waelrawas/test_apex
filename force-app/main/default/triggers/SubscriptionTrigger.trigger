
trigger SubscriptionTrigger on SBQQ__Subscription__c (after insert, after update,after insert, before update, after delete, before delete, after undelete) {

  new SubscriptionTriggerHandler().run();

}
