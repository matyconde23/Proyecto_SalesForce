trigger OpportunityChangeTanqueTrigger on Opportunity (before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        CambioTanqueOportunidadService.procesarCambioDeTanque(Trigger.new, Trigger.oldMap);
    }
}