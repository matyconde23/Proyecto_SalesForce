trigger OportunidadVendidaActualizada on Opportunity (after update) {
    List<Id> oppIds = new List<Id>();
    List<Opportunity> oportunidadesGanadas = new List<Opportunity>();

    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);

        // Detectar cambio a "Closed Won"
        if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            oppIds.add(opp.Id);
            oportunidadesGanadas.add(opp);
        }
    }

    if (!oppIds.isEmpty()) {
        // Ya existente: lógica para sumar ventas, etc.
        CerrarOportunidadVendida.procesarOportunidadesCerradas(oppIds);

        // Nueva llamada: actualizar marca preferida
        ActualizarMarcaPreferida.actualizarMarcaDesdeUltimoTanque(oportunidadesGanadas);
    }
}