trigger TanqueIndustrialTrigger on Tanque_Industrial__c (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        System.debug('🚀 Ejecutando trigger BEFORE INSERT de Tanque_Industrial__c');
        GeneradorNumeroSerie.asignarNumeroSerie(Trigger.new);
    }
}
