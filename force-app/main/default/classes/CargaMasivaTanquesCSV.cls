/**
 * Clase Apex para gestionar la carga masiva de tanques industriales
 * a partir de un archivo CSV procesado en el frontend (Lightning Web Component).
 *
 * Funcionalidades:
 * 1. Obtener la lista de tipos de tanque disponibles.
 * 2. Cargar múltiples registros de `Tanque_Industrial__c` basados en un CSV,
 *    validando que la capacidad del CSV coincida con la del tipo de tanque seleccionado.
 *
 * Este controlador está diseñado para ser llamado desde LWC usando `@AuraEnabled`.
 */
public with sharing class CargaMasivaTanquesCSV {

    /**
     * Método para obtener todos los tipos de tanque existentes.
     * Este método está marcado como `@AuraEnabled(cacheable=true)` para mejorar
     * el rendimiento en componentes Lightning Web.
     *
     * @return Lista de tipos de tanque (`Tipo_de_tanque__c`)
     */
    @AuraEnabled(cacheable=true)
    public static List<Tipo_de_tanque__c> obtenerTiposTanques() {
        return [SELECT Id, Name, Capacidad__c FROM Tipo_de_tanque__c];
    }

    /**
     *  Método para procesar la carga de tanques desde un archivo CSV ya parseado.
     * Recibe una lista de registros
     * valida que cada fila tenga una capacidad válida y coincidente con la del tipo seleccionado,
     * y crea los tanques válidos en Salesforce.
     *
     * @param tipoTanqueId ID del tipo de tanque seleccionado.
     * @param datos Lista de filas CSV, donde cada fila es un mapa con claves de campo.
     * @throws AuraHandledException si alguna fila tiene errores de formato o validación.
     */
    @AuraEnabled
    public static void crearTanquesDesdeCSV(Id tipoTanqueId, List<Map<String, String>> datos) {
        System.debug('🔁 INICIO - crearTanquesDesdeCSV');
        System.debug('📥 Tipo de tanque recibido: ' + tipoTanqueId);
        System.debug('📊 Total de filas recibidas desde CSV: ' + datos.size());

    // Obtener tipo de tanque
        Tipo_de_tanque__c tipo = [
            SELECT Id, Capacidad__c 
            FROM Tipo_de_tanque__c 
            WHERE Id = :tipoTanqueId
            LIMIT 1
        ];
        System.debug('✅ Tipo de tanque encontrado: ' + tipo.Id + ' - Capacidad: ' + tipo.Capacidad__c);

        List<Tanque_Industrial__c> tanques = new List<Tanque_Industrial__c>();
        List<String> errores = new List<String>();

        for (Integer i = 0; i < datos.size(); i++) {
            Map<String, String> fila = datos[i];
            String capacidadStr = fila.get('Capacidad__c');
            String numeroFabricacion = fila.get('Numero_fabricacion__c');

            System.debug('🔍 Fila ' + (i+1) + ': Capacidad=' + capacidadStr + ', Fabricación=' + numeroFabricacion);

            if (String.isNotBlank(capacidadStr)) {
                Decimal capacidadCSV;
                try {
                    capacidadCSV = Decimal.valueOf(capacidadStr);
                } catch (Exception e) {
                    errores.add('Fila ' + (i+1) + ': capacidad no numérica');
                    System.debug('❌ Fila ' + (i+1) + ' descartada: capacidad no numérica');
                    continue;
                }

                if (capacidadCSV != tipo.Capacidad__c) {
                    System.debug('⚠️ Fila ' + (i+1) + ' descartada: capacidad (' + capacidadCSV + ') no coincide con tipo (' + tipo.Capacidad__c + ')');
                    continue;
                }

                Tanque_Industrial__c t = new Tanque_Industrial__c();
                t.Tipo_de_tanque__c = tipo.Id;
                t.Numero_fabricacion__c = numeroFabricacion;
                tanques.add(t);

                System.debug('✅ Fila ' + (i+1) + ' válida. Tanque preparado para insertar.');
            } else {
                System.debug('⚠️ Fila ' + (i+1) + ' descartada: capacidad vacía');
            }
        }

        if (!tanques.isEmpty()) {
            System.debug('💾 Total de tanques válidos a insertar: ' + tanques.size());

            NumeroSerieGenerator.asignarNumeroSerie(tanques);
            System.debug('🔢 Números de serie asignados');

            insert tanques;
            System.debug('✅ Tanques insertados correctamente');

            for (Tanque_Industrial__c t : tanques) {
                System.debug('🌐 Generando link corto para tanque: ' + t.Id);
                ObtenerlinkCortoBitly.procesarLinkCortoAsync(t.Id);
            }
        } else {
            System.debug('🚫 No hay tanques válidos para insertar');
        }

        if (!errores.isEmpty()) {
            System.debug('⚠️ Errores encontrados durante la carga:\n' + String.join(errores, '\n'));
            throw new AuraHandledException('Errores en carga:\n' + String.join(errores, '\n'));
        }

        System.debug('✅ FIN - crearTanquesDesdeCSV');
        }
}