trigger PedidoConfirmadoTrigger on Pedido_tanque__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        GenerarTanqueDesdePedido.procesarPedidos(Trigger.new, Trigger.oldMap);
    }
}