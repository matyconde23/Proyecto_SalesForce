public class NumeroSerieGenerator {

    /**
     * Asigna automáticamente un número de serie único al campo Name de cada tanque.
     * El número de serie tiene el formato: PREFIJO-XXX
     * - PREFIJO: Compuesto por las 2 primeras letras de la marca y la capacidad del tipo de tanque.
     * - XXX: Número incremental de 3 dígitos, basado en los tanques ya existentes de ese tipo.
     *
     * @param tanques Lista de tanques a procesar, normalmente Trigger.new en un trigger before insert.
     */
    public static void asignarNumeroSerie(List<Tanque_Industrial__c> tanques) {
        if (tanques == null || tanques.isEmpty()) return;

        // Recolectar los IDs de los tipos de tanque usados en esta inserción
        Set<Id> tipoIds = new Set<Id>();
        for (Tanque_Industrial__c t : tanques) {
            if (t.Tipo_de_tanque__c != null) {
                tipoIds.add(t.Tipo_de_tanque__c);
            }
        }

        // Si no hay tipos, no se puede generar prefijos
        if (tipoIds.isEmpty()) return;

        // Consultar los tipos de tanque para obtener marca y capacidad
        Map<Id, Tipo_de_tanque__c> tipoMap = new Map<Id, Tipo_de_tanque__c>(
            [SELECT Id, Marca__c, Capacidad__c FROM Tipo_de_tanque__c WHERE Id IN :tipoIds]
        );

        // Generar prefijos únicos por tipo de tanque
        Map<Id, String> prefijosPorTipo = new Map<Id, String>();
        for (Id tipoId : tipoMap.keySet()) {
            prefijosPorTipo.put(tipoId, generarPrefijo(tipoMap.get(tipoId)));
        }

        // Buscar los nombres ya existentes para obtener el número más alto usado por prefijo
        Map<String, Integer> contadorPorPrefijo = new Map<String, Integer>();
        for (AggregateResult res : [
            SELECT Tipo_de_tanque__c, MAX(Name) maxName
            FROM Tanque_Industrial__c
            WHERE Tipo_de_tanque__c IN :tipoIds
            GROUP BY Tipo_de_tanque__c
        ]) {
            Id tipoId = (Id)res.get('Tipo_de_tanque__c');
            String maxName = (String)res.get('maxName');
            String prefijo = prefijosPorTipo.get(tipoId);

            // Extraer la parte numérica del nombre (después del guion)
            if (maxName != null && maxName.startsWith(prefijo + '-')) {
                String numeroStr = maxName.replace(prefijo + '-', '');
                try {
                    Integer numero = Integer.valueOf(numeroStr);
                    contadorPorPrefijo.put(prefijo, numero); // Guardar el último número usado
                } catch (Exception e) {
                    // Si el valor no es numérico, se ignora
                }
            }
        }

        // Asignar nombre a los tanques nuevos usando el siguiente número disponible
        for (Tanque_Industrial__c t : tanques) {
            if (t.Tipo_de_tanque__c == null) continue;

            String prefijo = prefijosPorTipo.get(t.Tipo_de_tanque__c);
            Integer siguiente = (contadorPorPrefijo.containsKey(prefijo) ? contadorPorPrefijo.get(prefijo) : 0) + 1;
            contadorPorPrefijo.put(prefijo, siguiente);

            // Formar el nombre con ceros a la izquierda
            t.Name = prefijo + '-' + padLeftWithZeros(siguiente, 3);
        }
    }

    /**
     * Genera un prefijo basado en las 2 primeras letras de la marca y la capacidad del tipo de tanque.
     * Ejemplo: Marca = "Petro", Capacidad = 500 → "PE500"
     *
     * @param tipo Objeto tipo de tanque
     * @return Prefijo generado
     */
    private static String generarPrefijo(Tipo_de_tanque__c tipo) {
        String marca = (tipo.Marca__c != null) ? tipo.Marca__c.substring(0, 2).toUpperCase() : 'XX';
        String capacidad = (tipo.Capacidad__c != null) ? String.valueOf(tipo.Capacidad__c) : '0000';
        return marca + capacidad;
    }

    /**
     * Rellena con ceros a la izquierda un número para alcanzar la longitud deseada.
     * Ejemplo: numero = 7, length = 3 → "007"
     *
     * @param numero Número a formatear
     * @param length Longitud final esperada del string
     * @return String con ceros a la izquierda
     */
    private static String padLeftWithZeros(Integer numero, Integer length) {
        String numStr = String.valueOf(numero);
        while (numStr.length() < length) {
            numStr = '0' + numStr;
        }
        return numStr;
    }
}
