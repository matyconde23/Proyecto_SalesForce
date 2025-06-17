public class GenerarTanqueDesdePedido {

    /**
     * Procesa los pedidos que han cambiado su estado a "Confirmado" y genera un tanque asociado,
     * el cual luego se asigna automáticamente a la oportunidad relacionada.
     *
     * Pasos:
     * 1. Detectar pedidos que pasaron a estado "Confirmado".
     * 2. Crear un nuevo tanque para cada pedido confirmado.
     * 3. Asignar el tanque a la oportunidad relacionada (removiendo el pedido).
     * 4. Cambiar el estado del nuevo tanque a "Reservado".
     *
     * @param pedidos Lista de pedidos modificados (Trigger.new).
     * @param pedidosAntiguos Mapa de pedidos anteriores (Trigger.oldMap).
     */
    public static void procesarPedidos(List<Pedido_tanque__c> pedidos, Map<Id, Pedido_tanque__c> pedidosAntiguos) {
        Set<Id> pedidosConfirmadosIds = new Set<Id>();

        // 🔍 Paso 1: Detectar cuáles pedidos cambiaron a estado "Confirmado"
        for (Pedido_tanque__c pedido : pedidos) {
            Pedido_tanque__c anterior = pedidosAntiguos.get(pedido.Id);
            if (pedido.Estado__c == 'Confirmado' && anterior.Estado__c != 'Confirmado') {
                pedidosConfirmadosIds.add(pedido.Id);
            }
        }

        //  Si no hay pedidos confirmados, salir del proceso
        if (pedidosConfirmadosIds.isEmpty()) return;

        // 🗂 Paso 2: Obtener los pedidos confirmados desde base de datos
        Map<Id, Pedido_tanque__c> pedidosConfirmadosMap = new Map<Id, Pedido_tanque__c>(
            [SELECT Id, Tipo_de_tanque__c FROM Pedido_tanque__c WHERE Id IN :pedidosConfirmadosIds]
        );

        // 🔗 Paso 3: Buscar oportunidades que tengan alguno de los pedidos confirmados
        List<Opportunity> oportunidades = [
            SELECT Id, Pedido_tanque__c
            FROM Opportunity
            WHERE Pedido_tanque__c IN :pedidosConfirmadosIds
        ];

        if (oportunidades.isEmpty()) return;

        // 🛠 Paso 4: Crear tanques industriales nuevos para cada pedido
        List<Tanque_Industrial__c> tanquesACrear = new List<Tanque_Industrial__c>();
        for (Opportunity opp : oportunidades) {
            Pedido_tanque__c pedido = pedidosConfirmadosMap.get(opp.Pedido_tanque__c);

            Tanque_Industrial__c nuevoTanque = new Tanque_Industrial__c();
            nuevoTanque.Tipo_de_tanque__c = pedido.Tipo_de_tanque__c;

            // Estado inicial: Disponible (para cumplir validaciones de asignación)
            nuevoTanque.Estado__c = 'Disponible';

            tanquesACrear.add(nuevoTanque);
        }

        // 🔨 Insertar los nuevos tanques
        insert tanquesACrear;

        //  Paso 5: Asignar el nuevo tanque a la oportunidad y remover el pedido
        List<Opportunity> oportunidadesActualizar = new List<Opportunity>();
        for (Integer i = 0; i < oportunidades.size(); i++) {
            Opportunity opp = oportunidades[i];
            Tanque_Industrial__c tanqueCreado = tanquesACrear[i];

            opp.Pedido_tanque__c = null;
            opp.Tanque_seleccionado__c = tanqueCreado.Id;

            oportunidadesActualizar.add(opp);
        }

        //  Actualizar las oportunidades con el nuevo tanque asignado
        update oportunidadesActualizar;

        // Paso 6: Cambiar estado de los tanques de "Disponible" a "Reservado"
        for (Tanque_Industrial__c t : tanquesACrear) {
            t.Estado__c = 'Reservado';
        }

        update tanquesACrear;
    }
}
