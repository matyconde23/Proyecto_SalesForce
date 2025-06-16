trigger ValidarLeadTrigger on Lead (before insert) {
    ValidacionLead.validarLeads(Trigger.new);
}