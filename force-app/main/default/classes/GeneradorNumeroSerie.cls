public class GeneradorNumeroSerie {

    /**
     * Asigna automáticamente un número de serie único al campo Name de cada tanque.
     * El número de serie tiene el formato: PREFIJO-XXX
     */
    public static void asignarNumeroSerie(List<Tanque_Industrial__c> tanques) {
        if (tanques == null || tanques.isEmpty()) {
            System.debug(' Lista de tanques vacía o nula. Fin del proceso.');
            return;
        }

        // Agrupar tanques por tipo
        Map<Id, List<Tanque_Industrial__c>> tanquesPorTipo = new Map<Id, List<Tanque_Industrial__c>>();
        Set<Id> tipoIds = new Set<Id>();

        for (Tanque_Industrial__c t : tanques) {
            if (t.Tipo_de_tanque__c != null) {
                tipoIds.add(t.Tipo_de_tanque__c);
                if (!tanquesPorTipo.containsKey(t.Tipo_de_tanque__c)) {
                    tanquesPorTipo.put(t.Tipo_de_tanque__c, new List<Tanque_Industrial__c>());
                }
                tanquesPorTipo.get(t.Tipo_de_tanque__c).add(t);
            }
        }

        if (tipoIds.isEmpty()) return;

        // Consultar los tipos de tanque
        Map<Id, Tipo_de_tanque__c> tipoMap = new Map<Id, Tipo_de_tanque__c>(
            [SELECT Id, Marca__c, Capacidad__c FROM Tipo_de_tanque__c WHERE Id IN :tipoIds]
        );

        // Generar prefijos por tipo
        Map<Id, String> prefijosPorTipo = new Map<Id, String>();
        for (Id tipoId : tipoMap.keySet()) {
            String prefijo = generarPrefijo(tipoMap.get(tipoId));
            prefijosPorTipo.put(tipoId, prefijo);
        }

        // Obtener el último número generado por tipo (no la cantidad)
        Map<Id, Integer> ultimoNumeroPorTipo = new Map<Id, Integer>();
        for (Id tipoId : tipoIds) {
            String prefijo = prefijosPorTipo.get(tipoId);
            
            List<Tanque_Industrial__c> tanquesExistentes = [
                SELECT Name 
                FROM Tanque_Industrial__c
                WHERE Tipo_de_tanque__c = :tipoId AND Name LIKE :prefijo + '-%'
                ORDER BY Name DESC
                LIMIT 1
            ];
            
            if (!tanquesExistentes.isEmpty()) {
                String nameUltimo = tanquesExistentes[0].Name;
                List<String> partes = nameUltimo.split('-');
                if (partes.size() == 2) {
                    try {
                        ultimoNumeroPorTipo.put(tipoId, Integer.valueOf(partes[1]));
                    } catch (Exception e) {
                        ultimoNumeroPorTipo.put(tipoId, 0);
                    }
                } else {
                    ultimoNumeroPorTipo.put(tipoId, 0);
                }
            } else {
                ultimoNumeroPorTipo.put(tipoId, 0);
            }
        }

        // Asignar nombre a cada tanque nuevo
        for (Id tipoId : tanquesPorTipo.keySet()) {
            List<Tanque_Industrial__c> lista = tanquesPorTipo.get(tipoId);
            String prefijo = prefijosPorTipo.get(tipoId);
            Integer contador = ultimoNumeroPorTipo.containsKey(tipoId) ? ultimoNumeroPorTipo.get(tipoId) : 0;

            for (Tanque_Industrial__c t : lista) {
                contador++;
                t.Name = prefijo + '-' + padLeftWithZeros(contador, 3);
            }

            ultimoNumeroPorTipo.put(tipoId, contador); // actualizar por si hay más
        }
    }

    private static String generarPrefijo(Tipo_de_tanque__c tipo) {
        String marca = (tipo.Marca__c != null) ? tipo.Marca__c.substring(0, 2).toUpperCase() : 'XX';
        String capacidad = (tipo.Capacidad__c != null) ? String.valueOf(tipo.Capacidad__c) : '0000';
        return marca + capacidad;
    }

    private static String padLeftWithZeros(Integer numero, Integer length) {
        String numStr = String.valueOf(numero);
        while (numStr.length() < length) {
            numStr = '0' + numStr;
        }
        return numStr;
    }
}
