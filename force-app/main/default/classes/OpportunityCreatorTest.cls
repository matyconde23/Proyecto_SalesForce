@isTest
public class OpportunityCreatorTest {

    /**
     * Test unitario para verificar el comportamiento del método
     * OpportunityCreator.crearOportunidadDesdeLead cuando hay un tanque disponible.
     *
     * Este test valida que:
     * - Se asigne correctamente un tanque disponible a la oportunidad.
     * - El precio de venta coincida con el del tipo de tanque.
     * - El estado del tanque se actualice a "Reservado".
     */
    @isTest
    static void testCrearOportunidadDesdeLead() {
        // 🔧 Crear tipo de tanque compatible con los datos del Lead
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Capacidad__c = 4000,
            Precio_de_lista__c = 14000,
            Marca__c = 'Marca Test'
        );
        insert tipo;

        // 🛢 Crear un tanque industrial disponible asociado al tipo
        Tanque_Industrial__c tanque = new Tanque_Industrial__c(
            name = 'Tanque ' + tipo.Marca__c + ' ' + tipo.Capacidad__c + ' cm3',
            Estado__c = 'Disponible',
            Tipo_de_tanque__c = tipo.Id
        );
        insert tanque;

        // 📋 Crear un Lead con capacidad y precio compatibles con el tipo de tanque
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'User',
            Company = 'Empresa Test',
            Capacidad__c = 4000,
            Precio_minimo__c = 12000,
            Precio_maximo__c = 18000,
            Status = 'Open - Not Contacted'
        );
        insert lead;

        // 🚀 Ejecutar el método que crea o actualiza la oportunidad
        Test.startTest();
        Opportunity opp = OpportunityCreator.crearOportunidadDesdeLead(lead.Id);
        Test.stopTest();

        // ✅ Validar que la oportunidad tiene un tanque asignado
        System.assertNotEquals(null, opp.Tanque_seleccionado__c, 'La oportunidad debería tener un tanque asignado');

        // ✅ Validar que el precio de la oportunidad coincida con el precio del tipo de tanque
        System.assertEquals(tipo.Precio_de_lista__c, opp.Precio_de_venta__c, 'El precio debe coincidir');

        // ✅ Validar que el tanque fue marcado como "Reservado"
        Tanque_Industrial__c tanqueActualizado = [
            SELECT Estado__c FROM Tanque_Industrial__c WHERE Id = :opp.Tanque_seleccionado__c
        ];
        System.assertEquals('Reservado', tanqueActualizado.Estado__c, 'El tanque debe estar reservado');
    }
}
