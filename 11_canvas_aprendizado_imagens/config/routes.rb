Rails.application.routes.draw do
  root 'canvas#index'
  post 'identificar', to: 'canvas#identify'
  post 'ensinar', to: 'canvas#teach'
  post 'treinamento/inicial', to: 'canvas#pretrain'
  post 'treinamento/zerar', to: 'canvas#reset_training'
  post 'treinamento/restaurar', to: 'canvas#restore_training'
  get 'base-imagens/:key', to: 'canvas#starter_image', defaults: { format: 'png' }
  get 'exemplos/:id', to: 'canvas#sample', format: false
end
