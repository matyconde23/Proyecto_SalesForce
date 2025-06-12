trigger TanqueIndustrialLinkTrigger on Tanque_Industrial__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        if (Trigger.new.size() == 1) {
            String idDelTanque = String.valueOf(Trigger.new[0].Id);
            System.debug('🚀 Encolando método @future para ID: ' + idDelTanque);
            ObtenerlinkCortoBitly.procesarLinkCortoAsync(idDelTanque);
        } else {
            System.debug('⛔ Saltando por inserción masiva');
        }
    }
}