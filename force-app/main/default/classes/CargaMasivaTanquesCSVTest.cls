@isTest
public class CargaMasivaTanquesCSVTest {

    @isTest
    static void testCrearTanquesDesdeCSV_Exitoso() {
        // Crear tipo de tanque
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo Test',
            Capacidad__c = 2000,
            Precio_de_lista__c = 100000,
            Marca__c = 'MarcaTest'
        );
        insert tipo;

        // Simular datos del CSV válidos
        List<Map<String, String>> datosCSV = new List<Map<String, String>>();
        for (Integer i = 0; i < 3; i++) {
            Map<String, String> fila = new Map<String, String>();
            fila.put('Capacidad__c', '2000');
            datosCSV.add(fila);
        }

        Test.startTest();
        CargaMasivaTanquesCSV.crearTanquesDesdeCSV(tipo.Id, datosCSV);
        Test.stopTest();

        // Verificamos que se crearon 3 tanques
        List<Tanque_Industrial__c> tanques = [
            SELECT Id, Tipo_de_tanque__c, Name FROM Tanque_Industrial__c WHERE Tipo_de_tanque__c = :tipo.Id
        ];
        System.assertEquals(3, tanques.size(), 'Deben haberse creado 3 tanques');
        System.assertNotEquals(null, tanques[0].Name, 'Los tanques deben tener número de serie');
    }

    @isTest
    static void testCrearTanquesDesdeCSV_ErrorCapacidadNoNumerica() {
        // Crear tipo de tanque
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo Error',
            Capacidad__c = 1000,
            Precio_de_lista__c = 80000,
            Marca__c = 'MarcaX'
        );
        insert tipo;

        // Simular fila con error
        List<Map<String, String>> datosCSV = new List<Map<String, String>>();
        Map<String, String> fila = new Map<String, String>();
        fila.put('Capacidad__c', 'no-numérico');
        datosCSV.add(fila);

        Test.startTest();
        try {
            CargaMasivaTanquesCSV.crearTanquesDesdeCSV(tipo.Id, datosCSV);
            System.assert(false, 'Debe lanzarse una excepción');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('capacidad no numérica'), 'El error debe mencionar la capacidad no numérica');
        }
        Test.stopTest();
    }

    @isTest
    static void testCrearTanquesDesdeCSV_CapacidadIncorrecta() {
        // Crear tipo de tanque
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo Mismatch',
            Capacidad__c = 3000,
            Precio_de_lista__c = 90000,
            Marca__c = 'MarcaZ'
        );
        insert tipo;

        // Simular capacidad incorrecta
        List<Map<String, String>> datosCSV = new List<Map<String, String>>();
        Map<String, String> fila = new Map<String, String>();
        fila.put('Capacidad__c', '4000');
        datosCSV.add(fila);

        Test.startTest();
        CargaMasivaTanquesCSV.crearTanquesDesdeCSV(tipo.Id, datosCSV);
        Test.stopTest();

        // No deben haberse insertado tanques
        List<Tanque_Industrial__c> tanques = [
            SELECT Id FROM Tanque_Industrial__c WHERE Tipo_de_tanque__c = :tipo.Id
        ];
        System.assertEquals(0, tanques.size(), 'No deben crearse tanques si la capacidad no coincide');
    }
}
