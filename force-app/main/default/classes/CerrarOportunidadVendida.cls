public with sharing class CerrarOportunidadVendida {

    /**
     * Procesa una lista de oportunidades marcadas como cerradas y ganadas.
     * 
     * - Marca el tanque seleccionado como "Vendido".
     * - Incrementa el contador de tanques comprados en la cuenta asociada.
     *
     * Este método debería ser llamado desde un trigger o proceso automatizado
     * cuando la etapa de la oportunidad cambia a "Closed Won".
     * 
     * @param oppIds Lista de IDs de oportunidades a procesar.
     */
    public static void procesarOportunidadesCerradas(List<Id> oppIds) {
        System.debug('🔍 Iniciando procesamiento de oportunidades cerradas. IDs recibidos: ' + oppIds);

        // Recuperar oportunidades desde la base de datos
        List<Opportunity> oportunidades = [
            SELECT Id, Tanque_seleccionado__c, AccountId
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
        System.debug('📦 Oportunidades recuperadas: ' + oportunidades);

        // Lista de tanques a actualizar y mapa de cuentas con cantidad de tanques a incrementar
        List<Tanque_Industrial__c> tanquesAActualizar = new List<Tanque_Industrial__c>();
        Map<Id, Decimal> cuentaASumar = new Map<Id, Decimal>();

        // Procesar cada oportunidad
        for (Opportunity opp : oportunidades) {
            System.debug('➡️ Procesando oportunidad: ' + opp.Id);

            // ✅ Si tiene un tanque seleccionado, se marca como "Vendido"
            if (opp.Tanque_seleccionado__c != null) {
                System.debug('🛢️ Tanque seleccionado encontrado: ' + opp.Tanque_seleccionado__c);
                tanquesAActualizar.add(new Tanque_Industrial__c(
                    Id = opp.Tanque_seleccionado__c,
                    Estado__c = 'Vendido'
                ));
            } else {
                System.debug('⚠️ No hay tanque seleccionado en esta oportunidad.');
            }

            // ✅ Si tiene una cuenta asociada, se acumula cantidad para luego actualizar
            if (opp.AccountId != null) {
                if (cuentaASumar.containsKey(opp.AccountId)) {
                    cuentaASumar.put(opp.AccountId, cuentaASumar.get(opp.AccountId) + 1);
                } else {
                    cuentaASumar.put(opp.AccountId, 1);
                }
                System.debug('👤 Cuenta a actualizar: ' + opp.AccountId + ' - Total acumulado: ' + cuentaASumar.get(opp.AccountId));
            } else {
                System.debug('⚠️ Oportunidad sin cuenta asociada.');
            }
        }

        // ✅ Actualizar el estado de los tanques a "Vendido"
        if (!tanquesAActualizar.isEmpty()) {
            System.debug('🔧 Actualizando tanques: ' + tanquesAActualizar);
            update tanquesAActualizar;
        } else {
            System.debug('ℹ️ No hay tanques para actualizar.');
        }

        // ✅ Actualizar el campo "Cantidad_de_tanques_comprados__c" de las cuentas
        if (!cuentaASumar.isEmpty()) {
            List<Account> cuentas = [
                SELECT Id, Cantidad_de_tanques_comprados__c
                FROM Account
                WHERE Id IN :cuentaASumar.keySet()
            ];
            System.debug('👥 Cuentas recuperadas: ' + cuentas);

            for (Account acc : cuentas) {
                // Si el valor actual es nulo, se toma como 0
                Decimal cantidadActual = acc.Cantidad_de_tanques_comprados__c != null ? acc.Cantidad_de_tanques_comprados__c : 0;
                acc.Cantidad_de_tanques_comprados__c = cantidadActual + cuentaASumar.get(acc.Id);
                System.debug('✅ Cuenta ' + acc.Id + ' actualizada con nuevo total de tanques: ' + acc.Cantidad_de_tanques_comprados__c);
            }

            update cuentas;
        } else {
            System.debug('ℹ️ No hay cuentas para actualizar.');
        }

        System.debug('✅ Finalizó procesamiento de oportunidades cerradas.');
    }
}
