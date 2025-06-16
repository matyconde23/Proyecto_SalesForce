@isTest
public class CrearPedidoDesdeConversionTest {

    /**
     * Test unitario que valida el comportamiento del método crearOportunidadDesdeLead
     * cuando no hay tanques disponibles para asignar. En ese caso:
     * - Se debe crear un pedido de tanque.
     * - No debe asignarse ningún tanque a la oportunidad.
     * - El precio de la oportunidad debe coincidir con el tipo de tanque compatible.
     */
    @isTest
    static void testCrearOportunidadConPedidoCuandoNoHayTanque() {
        // 🔧 Crear un tipo de tanque que cumpla con los criterios del Lead
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Capacidad__c = 4000,
            Precio_de_lista__c = 15000,
            Marca__c = 'SinTanque Marca'
        );
        insert tipo;

        // ❌ No insertamos ningún tanque → no habrá disponibilidad

        // 📋 Crear Lead que coincida con el tipo de tanque creado
        Lead lead = new Lead(
            FirstName = 'Test',
            LastName = 'PedidoTanque',
            Company = 'Empresa Sin Tanque',
            Capacidad__c = 4000,
            Precio_minimo__c = 14000,
            Precio_maximo__c = 16000,
            Status = 'Open - Not Contacted'
        );
        insert lead;

        // 🚀 Ejecutar lógica dentro de Test.startTest() y Test.stopTest()
        Test.startTest();
        Opportunity opp = CrearOportunidadAutomatica.crearOportunidadDesdeLead(lead.Id);
        Test.stopTest();

        // ✅ Validaciones

        // No debe haberse asignado un tanque
        System.assertEquals(null, opp.Tanque_seleccionado__c, 'No debería asignarse un tanque');

        // El precio de venta debe coincidir con el del tipo de tanque compatible
        System.assertEquals(tipo.Precio_de_lista__c, opp.Precio_de_venta__c, 'El precio debe coincidir con el tipo de tanque');

        // Debe haberse creado un Pedido_Tanque__c con estado Pendiente y tipo correcto
        List<Pedido_Tanque__c> pedidos = [
            SELECT Id, Estado__c, Tipo_de_tanque__c
            FROM Pedido_Tanque__c
            WHERE Tipo_de_tanque__c = :tipo.Id
        ];
        System.assertEquals(1, pedidos.size(), 'Debe haberse creado un pedido');
        System.assertEquals('Pendiente', pedidos[0].Estado__c, 'El estado debe ser Pendiente');
        System.assertEquals(pedidos[0].Id, opp.Pedido_Tanque__c, 'El pedido debe estar asignado a la oportunidad');
    }
}
