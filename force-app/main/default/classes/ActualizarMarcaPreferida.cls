/**
 * 🔧 Clase de utilidad para actualizar la marca preferida en una Cuenta,
 * basada en el tanque utilizado en la última oportunidad ganada (Closed Won).
 * 
 * 👉 Lógica:
 * - Se recorre una lista de oportunidades entrantes.
 * - Por cada oportunidad ganada (`StageName = 'Closed Won'`), se recopila la `AccountId`.
 * - Se consulta la última oportunidad ganada de cada cuenta (ordenadas por `CloseDate DESC`).
 * - Se extrae la marca del tipo de tanque usado en esa oportunidad.
 * - Se actualiza el campo `Marca_preferida__c` de la cuenta con esa marca.
 */
public class ActualizarMarcaPreferida {

    /**
     * Método principal que actualiza la marca preferida de las cuentas asociadas
     * a las oportunidades ganadas más recientes.
     *
     * @param oportunidades Lista de oportunidades (por lo general, `Trigger.new`)
     */
    public static void actualizarMarcaDesdeUltimoTanque(List<Opportunity> oportunidades) {
        Set<Id> cuentaIds = new Set<Id>();

        // Paso 1: Filtrar oportunidades ganadas con cuenta asociada
        for (Opportunity opp : oportunidades) {
            if (opp.StageName == 'Closed Won' && opp.AccountId != null) {
                cuentaIds.add(opp.AccountId);
            }
        }

        if (cuentaIds.isEmpty()) return;

        //  Paso 2: Obtener todas las oportunidades ganadas de esas cuentas,
        // ordenadas por fecha de cierre descendente (CloseDate DESC)
        Map<Id, Opportunity> ultimaOportunidadPorCuenta = new Map<Id, Opportunity>();

        List<Opportunity> oppsGanadas = [
            SELECT Id, AccountId, CloseDate, Tanque_seleccionado__c,
                   Tanque_seleccionado__r.Tipo_de_Tanque__r.Marca__c
            FROM Opportunity
            WHERE AccountId IN :cuentaIds AND StageName = 'Closed Won'
            ORDER BY CloseDate DESC
        ];

        //  Paso 3: Obtener la última oportunidad ganada por cuenta
        for (Opportunity opp : oppsGanadas) {
            if (!ultimaOportunidadPorCuenta.containsKey(opp.AccountId)) {
                ultimaOportunidadPorCuenta.put(opp.AccountId, opp);
            }
        }

        // Paso 4: Construir lista de cuentas a actualizar con la marca extraída
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

        // Paso 5: Realizar el update en las cuentas que tienen marca válida
        if (!cuentasActualizar.isEmpty()) {
            update cuentasActualizar;
        }
    }
}