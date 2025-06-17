/**
 * @description
 * Clase encargada de procesar oportunidades que pasaron al estado "Closed Won".
 *
 * Acciones que realiza:
 * - Marca el tanque seleccionado como "Vendido", si aún no lo estaba.
 * - Incrementa el contador de tanques comprados en la cuenta asociada.
 * - Asigna la marca del tipo de tanque como "Marca preferida" en la cuenta si aún no estaba definida.
 *
 * Este proceso se ejecuta desde el trigger OportunidadVendidaActualizada.
 *
 * @author Matías
 */
public with sharing class CerrarOportunidadVendida {

    /**
     * Procesa una lista de oportunidades cerradas como ganadas.
     *
     * Requisitos:
     * - La etapa de la oportunidad debe haber cambiado a "Closed Won".
     * - Debe tener un tanque seleccionado y una cuenta asociada.
     *
     * Lógica aplicada:
     * - Marca el tanque como "Vendido" si aún no lo está.
     * - Suma 1 al campo Cantidad_de_tanques_comprados__c de la cuenta.
     * - Si la cuenta no tiene marca preferida, la toma del Tipo de Tanque relacionado.
     *
     * @param oportunidades Lista de oportunidades que pasaron a "Closed Won"
     */
    public static void procesarOportunidadesCerradas(List<Opportunity> oportunidades) {
        Set<Id> tanqueIds = new Set<Id>();
        Set<Id> cuentaIds = new Set<Id>();

        // Identificar tanques y cuentas relacionados
        for (Opportunity opp : oportunidades) {
            if (opp.Tanque_seleccionado__c != null) {
                tanqueIds.add(opp.Tanque_seleccionado__c);
            }
            if (opp.AccountId != null) {
                cuentaIds.add(opp.AccountId);
            }
        }

        // Cargar tanques con el tipo de tanque y su marca
        Map<Id, Tanque_Industrial__c> tanquesMap = new Map<Id, Tanque_Industrial__c>(
            [SELECT Id, Estado__c, Tipo_de_Tanque__r.Marca__c
             FROM Tanque_Industrial__c
             WHERE Id IN :tanqueIds]
        );

        // Cargar cuentas relacionadas
        Map<Id, Account> cuentasMap = new Map<Id, Account>(
            [SELECT Id, Cantidad_de_tanques_comprados__c, Marca_preferida__c
             FROM Account
             WHERE Id IN :cuentaIds]
        );

        List<Tanque_Industrial__c> tanquesAActualizar = new List<Tanque_Industrial__c>();
        List<Account> cuentasAActualizar = new List<Account>();

        for (Opportunity opp : oportunidades) {
            Tanque_Industrial__c tanque = opp.Tanque_seleccionado__c != null ? tanquesMap.get(opp.Tanque_seleccionado__c) : null;
            Account cuenta = opp.AccountId != null ? cuentasMap.get(opp.AccountId) : null;

            // Solo procesar si el tanque no fue vendido aún
            if (tanque != null && tanque.Estado__c != 'Vendido') {
                tanque.Estado__c = 'Vendido';
                tanquesAActualizar.add(tanque);

                if (cuenta != null) {
                    // Sumar al contador de tanques comprados
                    Decimal actual = cuenta.Cantidad_de_tanques_comprados__c != null ? cuenta.Cantidad_de_tanques_comprados__c : 0;
                    cuenta.Cantidad_de_tanques_comprados__c = actual + 1;

                    // Asignar marca preferida si no está definida
                    String marca = tanque.Tipo_de_Tanque__r.Marca__c;
                    if (String.isBlank(cuenta.Marca_preferida__c) && !String.isBlank(marca)) {
                        cuenta.Marca_preferida__c = marca;
                    }

                    cuentasAActualizar.add(cuenta);
                }
            }
        }

        // Aplicar cambios si hay actualizaciones
        if (!tanquesAActualizar.isEmpty()) update tanquesAActualizar;
        if (!cuentasAActualizar.isEmpty()) update cuentasAActualizar;
    }
}
