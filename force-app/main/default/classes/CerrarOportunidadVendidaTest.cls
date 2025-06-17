@isTest
public class CerrarOportunidadVendidaTest {

    @isTest
    static void testCerrarOportunidadConTanqueYCuenta() {
        // Crear Tipo de Tanque con Marca
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tanque 1000L',
            Capacidad__c = 1000,
            Marca__c = 'Acuaplast',
            Precio_de_lista__c = 50000
        );
        insert tipo;

        // Crear Tanque Disponible
        Tanque_Industrial__c tanque = new Tanque_Industrial__c(
            Name = 'TANQUE-001',
            Estado__c = 'Disponible',
            Tipo_de_tanque__c = tipo.Id
        );
        insert tanque;

        // Crear Cuenta sin marca ni tanques comprados
        Account cuenta = new Account(
            Name = 'Cliente Test'
        );
        insert cuenta;

        // Crear Oportunidad con cuenta y tanque asignado
        Opportunity opp = new Opportunity(
            Name = 'Venta Test',
            StageName = 'Negotiation',
            CloseDate = Date.today(),
            AccountId = cuenta.Id,
            Tanque_seleccionado__c = tanque.Id
        );
        insert opp;

        // Simular cambio de etapa a Closed Won
        opp.StageName = 'Closed Won';
        update opp;

        // Simular trigger que llama a la clase (solo después del cambio de etapa)
        List<Opportunity> oportunidadesGanadas = [
            SELECT Id, AccountId, Tanque_seleccionado__c
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        Test.startTest();
        CerrarOportunidadVendida.procesarOportunidadesCerradas(oportunidadesGanadas);
        Test.stopTest();

        // Verificar actualizaciones

        Tanque_Industrial__c tanqueActualizado = [
            SELECT Estado__c FROM Tanque_Industrial__c WHERE Id = :tanque.Id
        ];
        System.assertEquals('Vendido', tanqueActualizado.Estado__c, 'El tanque debería estar vendido');

        Account cuentaActualizada = [
            SELECT Cantidad_de_tanques_comprados__c, Marca_preferida__c FROM Account WHERE Id = :cuenta.Id
        ];
        System.assertEquals(1, cuentaActualizada.Cantidad_de_tanques_comprados__c, 'Debe tener 1 tanque comprado');
        System.assertEquals('Acuaplast', cuentaActualizada.Marca_preferida__c, 'Debe tener asignada la marca preferida');
    }
}
