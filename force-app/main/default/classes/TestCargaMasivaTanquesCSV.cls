@isTest
public class TestCargaMasivaTanquesCSV{

    @isTest
    static void testCrearTanquesDesdeCSV() {
        // Crear un tipo de tanque válido
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo Test',
            Capacidad__c = 1000,
            Precio_de_lista__c = 50000,
            Marca__C = 'test'
        );
        insert tipo;

        // Simular datos del CSV como List<Map<String, String>>
        List<Map<String, String>> datosCSV = new List<Map<String, String>>();

        Map<String, String> fila1 = new Map<String, String>{ 'Capacidad__c' => '1000' };
        Map<String, String> fila2 = new Map<String, String>{ 'Capacidad__c' => '500' };  // No debe insertarse
        Map<String, String> fila3 = new Map<String, String>{ 'Capacidad__c' => '1000' };

        datosCSV.add(fila1);
        datosCSV.add(fila2);
        datosCSV.add(fila3);

        Test.startTest();
        String resultado = CargaMasivaTanquesCSV.crearTanquesDesdeCSV(datosCSV, tipo.Id);
        Test.stopTest();

        // Verificación
        System.assert(resultado.contains('2 tanques'), 'Debe insertarse solo 2 tanques válidos');

        List<Tanque_Industrial__c> tanques = [
            SELECT Id, Estado__c, Tipo_de_tanque__c FROM Tanque_Industrial__c
        ];

        System.assertEquals(2, tanques.size(), 'Deben haberse insertado 2 tanques');
        for (Tanque_Industrial__c t : tanques) {
            System.assertEquals('Disponible', t.Estado__c);
            System.assertEquals(tipo.Id, t.Tipo_de_tanque__c);
        }
    }
}
