public class CambioTanqueOportunidadService {

    /**
     * Procesa los cambios de tanque en una oportunidad.
     *
     * Si el campo `Tanque_seleccionado__c` cambia:
     * - Marca el tanque anterior como "Disponible".
     * - Marca el nuevo tanque como "Reservado".
     * - Actualiza en memoria el precio de venta (`Precio_de_venta__c`) de la oportunidad
     *   según el precio de lista del tipo de tanque asignado.
     *
     * Este método está diseñado para ser llamado desde un trigger `before update`.
     *
     * @param newList Lista de oportunidades nuevas (Trigger.new)
     * @param oldMap Mapa de versiones anteriores de las oportunidades (Trigger.oldMap)
     */
    public static void procesarCambioDeTanque(List<Opportunity> newList, Map<Id, Opportunity> oldMap) {
        // Lista de tanques que necesitan ser actualizados (cambio de estado)
        List<Tanque_Industrial__c> tanquesActualizar = new List<Tanque_Industrial__c>();

        // IDs de los nuevos tanques seleccionados para oportunidades
        Set<Id> nuevosTanquesIds = new Set<Id>();

        // Mapa que relaciona cada nuevo tanque con la oportunidad que lo seleccionó
        Map<Id, Opportunity> oportunidadesConNuevoTanque = new Map<Id, Opportunity>();

        // Iterar por todas las oportunidades para detectar cambios de tanque
        for (Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.Id);

            // Solo actuar si cambió el tanque seleccionado
            if (opp.Tanque_seleccionado__c != oldOpp.Tanque_seleccionado__c) {
                System.debug(' Cambio de tanque detectado en oportunidad: ' + opp.Id);

                // Si había un tanque anterior → se marca como Disponible
                if (oldOpp.Tanque_seleccionado__c != null) {
                    tanquesActualizar.add(new Tanque_Industrial__c(
                        Id = oldOpp.Tanque_seleccionado__c,
                        Estado__c = 'Disponible'
                    ));
                }

                // Si hay un nuevo tanque → se marca como Reservado
                if (opp.Tanque_seleccionado__c != null) {
                    tanquesActualizar.add(new Tanque_Industrial__c(
                        Id = opp.Tanque_seleccionado__c,
                        Estado__c = 'Reservado'
                    ));
                    nuevosTanquesIds.add(opp.Tanque_seleccionado__c);
                    oportunidadesConNuevoTanque.put(opp.Tanque_seleccionado__c, opp); // Mapeo tanque → oportunidad
                }
            }
        }

        // 🔧 Actualizar estados de los tanques si hay alguno que cambió
        if (!tanquesActualizar.isEmpty()) {
            update tanquesActualizar;
            System.debug('Tanques actualizados: ' + tanquesActualizar.size());
        }

        //  Obtener precio de lista del tipo de tanque y actualizar precio en oportunidad
        if (!nuevosTanquesIds.isEmpty()) {
            Map<Id, Tanque_Industrial__c> tanquesConTipo = new Map<Id, Tanque_Industrial__c>(
                [SELECT Id, Tipo_de_tanque__r.Precio_de_lista__c
                 FROM Tanque_Industrial__c
                 WHERE Id IN :nuevosTanquesIds]
            );

            for (Id tanqueId : tanquesConTipo.keySet()) {
                Opportunity opp = oportunidadesConNuevoTanque.get(tanqueId);
                if (opp != null) {
                    Decimal nuevoPrecio = tanquesConTipo.get(tanqueId).Tipo_de_tanque__r.Precio_de_lista__c;
                    opp.Precio_de_venta__c = nuevoPrecio;
                    System.debug(' Precio de venta actualizado en memoria para oportunidad ' + opp.Id + ': ' + nuevoPrecio);
                }
            }
        }
    }
}
