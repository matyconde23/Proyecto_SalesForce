trigger OportunidadVendidaActualizada on Opportunity (after update) {
    List<Opportunity> ganadas = new List<Opportunity>();

    for (Opportunity opp : Trigger.new) {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
            ganadas.add(opp);
        }
    }

    if (!ganadas.isEmpty()) {
        CerrarOportunidadVendida.procesarOportunidadesCerradas(ganadas);
    }
}