/**
 * @name : SubscriptionTriggerHandler
 * @description : Trigger handler for the Subscription Object to use in triggers
 * @author : WR
 * @date : 26/06/2021
 *
 */
public with sharing class SubscriptionTriggerHandler extends TriggerHandler {

    //empty constructor
    public SubscriptionTriggerHandler() {}

    public override void afterInsert() {
      SubscriptionService.updateConEndDate(Trigger.new);
    }
    public override void afterUpdate() {
      SubscriptionService.updateConEndDate(Trigger.new);
    }
}
