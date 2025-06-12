@isTest
public class TestCrearOportunidadDesdeCuenta {

    /**
     * 🧪 Test que valida la asignación exitosa de un tanque a una oportunidad,
     * cuando existe un tanque disponible que cumple con los requisitos de capacidad y precio.
     */
    @isTest
    static void testAsignarTanqueDisponible_OK() {
        // Crear un tipo de tanque que coincida con la cuenta
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Capacidad__c = 1000,
            Precio_de_lista__c = 80000
        );
        insert tipo;

        // Crear un tanque disponible asociado al tipo
        Tanque_Industrial__c tanque = new Tanque_Industrial__c(
            Estado__c = 'Disponible',
            Tipo_de_tanque__c = tipo.Id
        );
        insert tanque;

        // Crear una cuenta con requisitos compatibles
        Account cuenta = new Account(
            Name = 'Cuenta Test',
            Capacidad__c = 1000,
            Precio_minimo__c = 70000,
            Precio_maximo__c = 90000
        );
        insert cuenta;

        // Insertar una oportunidad que debería recibir el tanque automáticamente
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad OK',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = cuenta.Id
        );
        insert opp;

        // Validar que el tanque fue asignado correctamente
        Opportunity resultado = [SELECT Tanque_seleccionado__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertNotEquals(null, resultado.Tanque_seleccionado__c, 'El tanque debe haberse asignado.');
    }

    /**
     * 🧪 Test que valida que, si no hay tanques disponibles compatibles,
     * se genere automáticamente un Pedido_tanque__c y no se asigne tanque a la oportunidad.
     */
    @isTest
    static void testCrearPedidoSiNoHayTanque() {
        // Crear un tipo de tanque sin tanques físicos disponibles
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Capacidad__c = 2000,
            Precio_de_lista__c = 95000
        );
        insert tipo;

        // Crear una cuenta cuyos requisitos matchean con el tipo de tanque
        Account cuenta = new Account(
            Name = 'Cuenta Pedido',
            Capacidad__c = 2000,
            Precio_minimo__c = 80000,
            Precio_maximo__c = 100000
        );
        insert cuenta;

        // Crear una oportunidad vinculada a la cuenta
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad Pedido',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = cuenta.Id
        );
        insert opp;

        // Validar que NO se asignó un tanque
        Opportunity resultado = [SELECT Tanque_seleccionado__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, resultado.Tanque_seleccionado__c, 'No debe asignarse tanque.');

        // Validar que SÍ se creó un pedido
        List<Pedido_tanque__c> pedidos = [SELECT Id FROM Pedido_tanque__c];
        System.assertEquals(1, pedidos.size(), 'Debe crearse un pedido.');
    }

    /**
     * 🧪 Test que valida que si no hay ningún tipo de tanque compatible con la capacidad y precios de la cuenta,
     * se bloquee la creación de la oportunidad con un error controlado.
     */
    @isTest
    static void testBloqueoDeOportunidad() {
        // Crear cuenta con requerimientos que no matchean con ningún tipo
        Account cuenta = new Account(
            Name = 'Cuenta Sin Match',
            Capacidad__c = 3000,
            Precio_minimo__c = 100000,
            Precio_maximo__c = 120000
        );
        insert cuenta;

        // Crear oportunidad que no debería poder insertarse
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad Bloqueada',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = cuenta.Id
        );

        // Validar que se lanza una excepción y no se inserta la oportunidad
        Test.startTest();
        try {
            insert opp;
            System.assert(false, 'Debe lanzarse un error y no crearse la oportunidad');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('No se puede crear la oportunidad'), 'Mensaje de error esperado.');
        }
        Test.stopTest();
    }
}
