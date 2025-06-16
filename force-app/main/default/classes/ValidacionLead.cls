public with sharing class ValidacionLead {
     public static void validarLeads(List<Lead> leads) {
        for (Lead l : leads) {
            System.debug('🔍 Validando Lead: ' + l);

            if (l.Capacidad__c != null && l.Precio_minimo__c != null && l.Precio_maximo__c != null) {
                System.debug('✅ Campos completos. Capacidad: ' + l.Capacidad__c +
                             ', Precio mínimo: ' + l.Precio_minimo__c +
                             ', Precio máximo: ' + l.Precio_maximo__c);

                List<Tipo_de_tanque__c> tipos = [
                    SELECT Id
                    FROM Tipo_de_tanque__c
                    WHERE Capacidad__c = :l.Capacidad__c
                    AND Precio_de_lista__c >= :l.Precio_minimo__c
                    AND Precio_de_lista__c <= :l.Precio_maximo__c
                    LIMIT 1
                ];

                System.debug('🔎 Tipos de tanque encontrados: ' + tipos);

                if (tipos.isEmpty()) {
                    System.debug('❌ No hay ningún tipo de tanque compatible. Lanzando error.');
                    l.addError('No hay tanques en nuestro catálogo que coincidan con la capacidad y el rango de precios indicado.');
                } else {
                    System.debug('✅ Se encontró al menos un tipo compatible. Todo ok.');
                }
            } else {
                System.debug('⚠️ Campos insuficientes para validar el Lead. Se omite la verificación.');
            }
        }
    }
}