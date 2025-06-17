public class CrearOportunidadDesdeCuenta {

    public static void procesarTanques(List<Opportunity> oportunidades) {
        Set<Id> tanqueIds = new Set<Id>();
        Map<Id, Opportunity> oportunidadesConTanque = new Map<Id, Opportunity>();

        for (Opportunity opp : oportunidades) {
            System.debug(' Revisando oportunidad: ' + opp.Id);
            if (opp.Tanque_Seleccionado__c != null) {
                System.debug('Tiene tanque seleccionado: ' + opp.Tanque_Seleccionado__c);
                tanqueIds.add(opp.Tanque_Seleccionado__c);
                oportunidadesConTanque.put(opp.Tanque_Seleccionado__c, opp);
            } else {
                System.debug(' Oportunidad sin tanque: ' + opp.Id);
            }
        }

        if (tanqueIds.isEmpty()) {
            System.debug(' No hay tanques a procesar');
            return;
        }

        Map<Id, Tanque_Industrial__c> tanquesMap = new Map<Id, Tanque_Industrial__c>(
            [SELECT Id, Estado__c, Tipo_de_Tanque__r.Precio_de_lista__c
             FROM Tanque_Industrial__c
             WHERE Id IN :tanqueIds]
        );

        System.debug(' Tanques obtenidos: ' + tanquesMap.keySet());

        List<Tanque_Industrial__c> tanquesParaActualizar = new List<Tanque_Industrial__c>();

        for (Id tanqueId : oportunidadesConTanque.keySet()) {
            Opportunity opp = oportunidadesConTanque.get(tanqueId);
            Tanque_Industrial__c tanque = tanquesMap.get(tanqueId);

            if (tanque == null) {
                System.debug(' Tanque no encontrado: ' + tanqueId);
                opp.addError('El tanque seleccionado no existe.');
                continue;
            }

            System.debug('🔍 Estado del tanque: ' + tanque.Estado__c);
            if (tanque.Estado__c != 'Disponible') {
                System.debug(' Tanque no disponible: ' + tanque.Id);
                opp.addError('El tanque seleccionado no está disponible.');
                continue;
            }

            Decimal precio = tanque.Tipo_de_Tanque__r.Precio_de_lista__c;
            System.debug(' Asignando precio ' + precio + ' a oportunidad ' + opp.Id);

            opp.Amount = precio;
            tanque.Estado__c = 'Reservado';
            tanquesParaActualizar.add(tanque);
        }

        if (!tanquesParaActualizar.isEmpty()) {
            System.debug(' Actualizando tanques reservados: ' + tanquesParaActualizar.size());
            update tanquesParaActualizar;
        } else {
            System.debug('ℹ No hay tanques que actualizar');
        }

        // 🚨 FALTA actualizar oportunidades si vas a persistir el Amount
        // update oportunidades; ← podés agregar esto si esperás guardar el nuevo Amount
    }
}
