@isTest
public class OpportunityCloseWonTest {
    

    @isTest
    static void testProcesarOportunidadesCerradas() {
        // Crear cuenta de prueba
        Account cuenta = new Account(Name = 'Cuenta Cliente', Cantidad_de_tanques_comprados__c = 0);
        insert cuenta;

        // Crear tipo de tanque
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Name = 'Tipo 3000',
            Capacidad__c = 3000,
            Marca__c = 'TE',
            Precio_de_lista__c = 15000
        );
        insert tipo;

        // Crear tanque disponible
        Tanque_Industrial__c tanque = new Tanque_Industrial__c(
            Name = 'TE3000-001',
            Tipo_de_tanque__c = tipo.Id,
            Estado__c = 'Reservado'
        );
        insert tanque;

        // Crear oportunidad con tanque
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad Vendida',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = cuenta.Id,
            Tanque_seleccionado__c = tanque.Id
        );
        insert opp;

        // Ejecutar método
        Test.startTest();
        OpportunityCloseWon.procesarOportunidadesCerradas(new List<Id>{ opp.Id });
        Test.stopTest();

        // Verificar tanque actualizado a "Vendido"
        Tanque_Industrial__c tanqueActualizado = [
            SELECT Id, Estado__c 
            FROM Tanque_Industrial__c 
            WHERE Id = :tanque.Id
        ];
        System.assertEquals('Vendido', tanqueActualizado.Estado__c, 'El tanque debe estar en estado Vendido');

        // Verificar que la cuenta tenga 1 tanque comprado
        Account cuentaActualizada = [
            SELECT Id, Cantidad_de_tanques_comprados__c 
            FROM Account 
            WHERE Id = :cuenta.Id
        ];
        System.assertEquals(1, cuentaActualizada.Cantidad_de_tanques_comprados__c, 'La cuenta debe tener 1 tanque comprado');
    }
}
