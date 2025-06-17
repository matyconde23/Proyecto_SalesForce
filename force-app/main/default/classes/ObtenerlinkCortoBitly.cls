public with sharing class ObtenerlinkCortoBitly {

    /**
     * Método asincrónico que genera y asigna un link corto de Bitly a un tanque industrial.
     * 
     * Este método debe ejecutarse con anotación @future(callout=true) ya que realiza una llamada HTTP externa.
     * 
     * Id del tanque al que se le asignará el link corto.
     */
    @future(callout=true)
    public static void procesarLinkCortoAsync(String tanqueId) {
        System.debug(' [INICIO] procesarLinkCortoAsync');
        System.debug(' ID recibido: ' + tanqueId);

        try {
            // Obtener el tanque desde la base de datos
            Tanque_Industrial__c tanque = [
                SELECT Id, URL__c 
                FROM Tanque_Industrial__c 
                WHERE Id = :tanqueId 
                LIMIT 1
            ];
            System.debug(' Tanque encontrado: ' + tanque.Id);

            // Construir URL larga del registro en Lightning
            String baseUrl = URL.getOrgDomainUrl().toExternalForm();
            System.debug(' Dominio Salesforce: ' + baseUrl);

            String linkLargo = baseUrl + '/lightning/r/Tanque_Industrial__c/' + tanque.Id + '/view';
            System.debug(' URL larga generada: ' + linkLargo);

            // Obtener la versión acortada usando la API de Bitly
            String shortUrl = obtenerShortLinkBitly(linkLargo);
            System.debug(' Resultado de obtenerShortLinkBitly: ' + shortUrl);

            // Si se obtuvo correctamente el link corto, se actualiza el tanque
            if (shortUrl != null) {
                tanque.URL__c = shortUrl;
                update tanque;
                System.debug(' Link corto guardado en tanque: ' + shortUrl);
            } else {
                System.debug(' No se generó el link corto (shortUrl es null)');
            }

        } catch (Exception e) {
            System.debug(' Excepción en procesarLinkCortoAsync: ' + e.getMessage());
        }

        System.debug(' [FIN] procesarLinkCortoAsync');
    }

    /**
     * Realiza la llamada HTTP a la API de Bitly para acortar una URL larga.
     * 
     * @param linkLargo URL completa del registro en Salesforce que se quiere acortar.
     * @return Link corto generado por Bitly o null si hubo error.
     */
    private static String obtenerShortLinkBitly(String linkLargo) {
    System.debug(' Entrando a obtenerShortLinkBitly con URL: ' + linkLargo);

    // Crear la solicitud HTTP
    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://api-ssl.bitly.com/v4/shorten');
    req.setMethod('POST');
    req.setHeader('Authorization', 'Bearer 4a729ff114cb47bdd7fee13d18fc074193baafc4'); // 🔐 Token Bitly (¡debe ocultarse en producción!)
    req.setHeader('Content-Type', 'application/json');

    // Armar payload JSON
    req.setBody('{"long_url": "' + linkLargo + '"}');
    System.debug(' Payload enviado a Bitly: ' + req.getBody());

    Http http = new Http();
    try {
        // Enviar la solicitud a Bitly
        HttpResponse res = http.send(req);
        System.debug(' Código de respuesta Bitly: ' + res.getStatusCode());
        System.debug(' Cuerpo respuesta Bitly: ' + res.getBody());

        // Si la respuesta fue exitosa (200 o 201), extraer el link
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String linkCorto = (String) json.get('link');
            System.debug('Link corto recibido: ' + linkCorto);
            return linkCorto;
        } else {
            System.debug(' Bitly respondió con código inesperado: ' + res.getStatusCode() + '. Usando link largo.');
            return linkLargo; //  Retornar el link largo si Bitly no respondió correctamente
        }

    } catch (Exception e) {
        System.debug(' Excepción al llamar a Bitly: ' + e.getMessage());
        return linkLargo;
    } 
}

}
