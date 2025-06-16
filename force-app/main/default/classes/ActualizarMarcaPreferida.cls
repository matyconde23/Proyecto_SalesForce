public class ActualizarMarcaPreferida {

    public static void actualizarMarcaDesdeUltimoTanque(List<Opportunity> oportunidades) {
        Set<Id> cuentaIds = new Set<Id>();

        for (Opportunity opp : oportunidades) {
            if (opp.StageName == 'Closed Won' && opp.AccountId != null) {
                cuentaIds.add(opp.AccountId);
            }
        }

        if (cuentaIds.isEmpty()) return;

        // Buscar la última oportunidad ganada por cuenta
        Map<Id, Opportunity> ultimaOportunidadPorCuenta = new Map<Id, Opportunity>();

        List<Opportunity> oppsGanadas = [
            SELECT Id, AccountId, CloseDate, Tanque_seleccionado__c,
                Tanque_seleccionado__r.Tipo_de_Tanque__r.Marca__c
            FROM Opportunity
            WHERE AccountId IN :cuentaIds AND StageName = 'Closed Won'
            ORDER BY CloseDate DESC
        ];

        for (Opportunity opp : oppsGanadas) {
            if (!ultimaOportunidadPorCuenta.containsKey(opp.AccountId)) {
                ultimaOportunidadPorCuenta.put(opp.AccountId, opp);
            }
        }

        // Armar lista de cuentas a actualizar
        List<Account> cuentasActualizar = new List<Account>();

        for (Id cuentaId : ultimaOportunidadPorCuenta.keySet()) {
            Opportunity ultimaOpp = ultimaOportunidadPorCuenta.get(cuentaId);

            String marca = ultimaOpp.Tanque_seleccionado__r?.Tipo_de_Tanque__r?.Marca__c;

            if (marca != null) {
                Account cuenta = new Account(
                    Id = cuentaId,
                    Marca_preferida__c = marca
                );
                cuentasActualizar.add(cuenta);
            }
        }

        if (!cuentasActualizar.isEmpty()) {
            update cuentasActualizar;
        }
    }
}
