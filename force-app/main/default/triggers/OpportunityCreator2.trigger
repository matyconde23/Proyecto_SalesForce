trigger OpportunityCreator2 on Opportunity (before insert) {
	CrearOportunidadDesdeCuenta.asignarTanqueDisponible(Trigger.new);
}