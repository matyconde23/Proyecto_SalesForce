@isTest
public class UpdateMarcaPreferidaTest {

    @isTest
    static void testActualizarMarcaDesdeUltimoTanque() {
        // 1. Crear un Tipo de Tanque con Marca
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(
            Capacidad__c = 3000,
            Precio_de_lista__c = 100000,
            Marca__c = 'MarcaTest'
        );
        insert tipo;

        // 2. Crear un Tanque relacionado a ese Tipo
        Tanque_Industrial__c tanque = new Tanque_Industrial__c(
            Tipo_de_tanque__c = tipo.Id,
            Estado__c = 'Vendido'
        );
        insert tanque;

        // 3. Crear una Cuenta
        Account cuenta = new Account(
            Name = 'Cuenta Test'
        );
        insert cuenta;

        // 4. Crear una Oportunidad "Closed Won" con ese tanque
        Opportunity opp = new Opportunity(
            Name = 'Oportunidad Ganada',
            StageName = 'Closed Won',
            CloseDate = Date.today(),
            AccountId = cuenta.Id,
            Tanque_seleccionado__c = tanque.Id
        );
        insert opp;

        // 5. Ejecutar método de lógica
        Test.startTest();
        UpdateMarcaPreferida.actualizarMarcaDesdeUltimoTanque(new List<Opportunity>{opp});
        Test.stopTest();

        // 6. Verificar que la cuenta fue actualizada con la marca del tanque
        Account cuentaActualizada = [SELECT Marca_preferida__c FROM Account WHERE Id = :cuenta.Id];
        System.assertEquals('MarcaTest', cuentaActualizada.Marca_preferida__c, 'La marca preferida debe coincidir con la del tanque');
    }
}
