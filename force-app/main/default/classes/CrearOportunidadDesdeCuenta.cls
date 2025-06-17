public class CrearOportunidadDesdeCuenta {

    public static void procesarTanques(List<Opportunity> oportunidades) {
        Set<Id> tanqueIds = new Set<Id>();
        Map<Id, Opportunity> oportunidadesConTanque = new Map<Id, Opportunity>();

        for (Opportunity opp : oportunidades) {
            if (opp.Tanque_Seleccionado__c != null) {
                tanqueIds.add(opp.Tanque_Seleccionado__c);
                oportunidadesConTanque.put(opp.Tanque_Seleccionado__c, opp);
            }
        }

        if (tanqueIds.isEmpty()) return;

        Map<Id, Tanque_Industrial__c> tanquesMap = new Map<Id, Tanque_Industrial__c>(
            [SELECT Id, Estado__c, Tipo_de_Tanque__r.Precio_de_lista__c
             FROM Tanque_Industrial__c
             WHERE Id IN :tanqueIds]
        );

        List<Tanque_Industrial__c> tanquesParaActualizar = new List<Tanque_Industrial__c>();

        for (Id tanqueId : oportunidadesConTanque.keySet()) {
            Opportunity opp = oportunidadesConTanque.get(tanqueId);
            Tanque_Industrial__c tanque = tanquesMap.get(tanqueId);

            if (tanque == null) {
                opp.addError('El tanque seleccionado no existe.');
                continue;
            }

            if (tanque.Estado__c != 'Disponible') {
                opp.addError('El tanque seleccionado no está disponible.');
                continue;
            }

            // ✅ Asignar el precio correctamente
            opp.Amount = tanque.Tipo_de_Tanque__r.Precio_de_lista__c;

            // Cambiar estado del tanque
            tanque.Estado__c = 'Reservado';
            tanquesParaActualizar.add(tanque);
        }

        if (!tanquesParaActualizar.isEmpty()) {
            update tanquesParaActualizar;
        }
    }
}
