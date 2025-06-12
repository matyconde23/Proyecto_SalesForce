public with sharing class CargaMasivaTanquesCSV {

    @AuraEnabled(cacheable=true)
    public static List<Tipo_de_tanque__c> getTipos() {
        return [SELECT Id, Name, Capacidad__c FROM Tipo_de_tanque__c];
    }

    @AuraEnabled
    public static void crearTanquesDesdeCSV(Id tipoTanqueId, List<Map<String, String>> datos) {
        Tipo_de_tanque__c tipo = [
            SELECT Id, Capacidad__c 
            FROM Tipo_de_tanque__c 
            WHERE Id = :tipoTanqueId
            LIMIT 1
        ];

        List<Tanque_Industrial__c> tanques = new List<Tanque_Industrial__c>();
        List<String> errores = new List<String>();

        for (Integer i = 0; i < datos.size(); i++) {
            Map<String, String> fila = datos[i];
            String capacidadStr = fila.get('Capacidad__c');

            if (String.isNotBlank(capacidadStr)) {
                Decimal capacidadCSV;
                try {
                    capacidadCSV = Decimal.valueOf(capacidadStr);
                } catch (Exception e) {
                    errores.add('Fila ' + (i+1) + ': capacidad no numérica');
                    continue;
                }

                if (capacidadCSV != tipo.Capacidad__c) {
                    
                    continue;
                }

                // OK: crear tanque
                Tanque_Industrial__c t = new Tanque_Industrial__c();
                t.Tipo_de_tanque__c = tipo.Id;
                tanques.add(t);
            }
        }

        if (!tanques.isEmpty()) {
            insert tanques;
        }

        if (!errores.isEmpty()) {
            throw new AuraHandledException('Errores en carga:\n' + String.join(errores, '\n'));
        }
    }
}