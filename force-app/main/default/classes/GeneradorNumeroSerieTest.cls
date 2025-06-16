@isTest
public class GeneradorNumeroSerieTest {

    @isTest
    static void testProcesarPedidos() {
        // Crear tipo de tanque
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo 2000',
            Capacidad__c = 2000,
            Precio_de_lista__c = 20000,
            Marca__c = 'TE'
        );
        insert tipo;

        // Crear pedido en estado inicial "Pendiente"
        Pedido_tanque__c pedido = new Pedido_tanque__c(
            Tipo_de_tanque__c = tipo.Id,
            Estado__c = 'Pendiente'
        );
        insert pedido;

        // Crear oportunidad con ese pedido
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad con pedido',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            Pedido_tanque__c = pedido.Id
        );
        insert opp;

        // Simular cambio de estado del pedido a "Confirmado"
        pedido.Estado__c = 'Confirmado';

        Test.startTest();
        GenerarTanqueDesdePedido.procesarPedidos(
            new List<Pedido_tanque__c>{ pedido },
            new Map<Id, Pedido_tanque__c>{ pedido.Id => new Pedido_tanque__c(
                Id = pedido.Id,
                Estado__c = 'Pendiente',
                Tipo_de_tanque__c = tipo.Id
            )}
        );
        Test.stopTest();

        // Verificar que se creó un tanque asociado a la oportunidad
        Opportunity oppActualizada = [
            SELECT Id, Tanque_seleccionado__c, Pedido_tanque__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        System.assertNotEquals(null, oppActualizada.Tanque_seleccionado__c, 'Debe haberse asignado un tanque nuevo');
        System.assertEquals(null, oppActualizada.Pedido_tanque__c, 'El campo Pedido_tanque__c debe haberse limpiado');

        // Verificar estado del tanque
        Tanque_Industrial__c tanque = [
            SELECT Id, Estado__c, Tipo_de_tanque__c
            FROM Tanque_Industrial__c
            WHERE Id = :oppActualizada.Tanque_seleccionado__c
        ];

        System.assertEquals('Reservado', tanque.Estado__c, 'El tanque debe estar en estado Reservado');
        System.assertEquals(tipo.Id, tanque.Tipo_de_tanque__c, 'El tanque debe ser del tipo correcto');
    }
}
