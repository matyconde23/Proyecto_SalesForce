@isTest
private class ObtenerLinkCortoBitlyTest {

    // Mock para simular la respuesta de Bitly
    public class BitlyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"link": "https://bit.ly/fake-link"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @isTest
    static void testProcesarLinkCortoAsync() {
        // Insertar un tanque de prueba
        Tipo_de_tanque__c tipo = new Tipo_de_tanque__c(Name = 'Tipo A', Capacidad__c = 1000, Marca__c = 'TA', Precio_de_lista__c = 10000);
        insert tipo;

        Tanque_Industrial__c tanque = new Tanque_Industrial__c(
            Name = 'TA1000-001',
            Tipo_de_tanque__c = tipo.Id,
            Estado__c = 'Disponible'
        );
        insert tanque;

        // Configurar el mock
        Test.setMock(HttpCalloutMock.class, new BitlyMock());

        // Llamar al método asincrónico
        Test.startTest();
        ObtenerlinkCortoBitly.procesarLinkCortoAsync(tanque.Id);
        Test.stopTest();

        // Verificar que el campo URL__c se haya actualizado
        Tanque_Industrial__c actualizado = [
            SELECT Id, URL__c FROM Tanque_Industrial__c WHERE Id = :tanque.Id
        ];
        System.assertNotEquals(null, actualizado.URL__c, 'El tanque debe tener una URL corta generada');
        System.assertEquals('https://bit.ly/fake-link', actualizado.URL__c, 'La URL debe coincidir con el mock');
    }
}
