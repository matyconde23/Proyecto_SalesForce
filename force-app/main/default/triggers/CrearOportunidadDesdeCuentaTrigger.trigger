trigger CrearOportunidadDesdeCuentaTrigger on Opportunity (before insert) {
    if (Trigger.isBefore && Trigger.isInsert) {
        CrearOportunidadDesdeCuenta.procesarTanques(Trigger.new);
    }
}
