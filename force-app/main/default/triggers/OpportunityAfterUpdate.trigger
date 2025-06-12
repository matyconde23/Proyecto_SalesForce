trigger OpportunityAfterUpdate on Opportunity (after update) {
    List<Id> oppIds = new List<Id>();
    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        
        // Detectar cambio a "Closed Won"
        if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            oppIds.add(opp.Id);
        }
    }

    if (!oppIds.isEmpty()) {
        OpportunityCloseWon.procesarOportunidadesCerradas(oppIds);
    }
}