trigger ConversionLeadTrigger on Lead (after update) {
    for (Lead l : Trigger.new) {
        Lead old = Trigger.oldMap.get(l.Id);
        if (!old.IsConverted && l.IsConverted) {
            try {
                CrearOportunidadAutomatica.crearOportunidadDesdeLead(l.Id);
            } catch (Exception e) {
                System.debug('Error creando oportunidad desde lead: ' + e.getMessage());
            }
        }
    }
}