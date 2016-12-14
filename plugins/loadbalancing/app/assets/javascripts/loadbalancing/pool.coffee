$(document).on 'modal:contentUpdated', (e) ->
  $form = $('form[id=pool_form]')

  $form.find('.form-group.pool_session_persistence_type select').change () ->
    value = $(this).find(":selected").val()
    if value=='APP_COOKIE'
      $form.find(".form-group.pool_session_persistence_cookie_name").removeClass('hidden')
      $form.find(".form-group.pool_session_persistence_cookie_name").removeClass('disabled')
    else
      $form.find(".form-group.pool_session_persistence_cookie_name").addClass('hidden')
      $form.find(".form-group.pool_session_persistence_cookie_name").addClass('disabled')

  $form.find('.form-group.pool_listener_id select').change () ->
    value = $(this).find(":selected").val()
    if value!=''
      $form.find(".form-group.pool_loadbalancer_id select").val("")

  $form.find('.form-group.pool_loadbalancer_id select').change () ->
    value = $(this).find(":selected").val()
    if value!=''
      $form.find(".form-group.pool_listener_id select").val("")