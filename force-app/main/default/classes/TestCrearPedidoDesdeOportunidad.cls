@isTest
public class TestCrearPedidoDesdeOportunidad {

    /**
     * 🧪 Test unitario que valida que, cuando no hay tanques industriales disponibles
     * que cumplan con los requisitos de la cuenta asociada a una oportunidad,
     * se genere automáticamente un pedido de tanque (`Pedido_tanque__c`).
     */
    @isTest
    static void testCrearPedidoCuandoNoHayTanqueDisponible() {
        // Paso 1: Crear un tipo de tanque con capacidad y precio que serán compatibles con la cuenta
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo 1000L',
            Capacidad__c = 1000,
            Precio_de_lista__c = 85000
        );
        insert tipo;

        // ⚠️ No creamos ningún Tanque_Industrial__c para simular que no hay tanques disponibles

        // Paso 2: Crear una cuenta que tenga los mismos requisitos de capacidad y rango de precios
        Account cuenta = new Account(
            Name = 'Cliente sin tanques',
            Capacidad__c = 1000,
            Precio_minimo__c = 80000,
            Precio_maximo__c = 90000
        );
        insert cuenta;

        // Paso 3: Crear una oportunidad que esté asociada a la cuenta anterior
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad sin tanque',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            AccountId = cuenta.Id
        );
        insert opp;

        // Paso 4: Validar que la oportunidad NO tenga tanque asignado
        Opportunity resultado = [SELECT Tanque_seleccionado__c FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(null, resultado.Tanque_seleccionado__c, 'No debe asignarse un tanque');

        // Paso 5: Verificar que se haya creado un pedido de tanque asociado al tipo compatible
        List<Pedido_tanque__c> pedidos = [
            SELECT Id, Tipo_de_tanque__c, Estado__c
            FROM Pedido_tanque__c
            WHERE Tipo_de_tanque__c = :tipo.Id
        ];
        System.assertEquals(1, pedidos.size(), 'Debe crearse un pedido asociado al tipo');
        System.assertEquals('Pendiente', pedidos[0].Estado__c, 'El estado del pedido debe ser Pendiente');
    }
}
