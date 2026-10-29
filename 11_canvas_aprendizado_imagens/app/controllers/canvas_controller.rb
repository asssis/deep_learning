class CanvasController < ApplicationController
  rescue_from ArgumentError, with: :invalid_input

  def index
    @summary = repository.summary
  end

  def pretrain
    render json: repository.pretrain
  end

  def reset_training
    render json: repository.reset
  end

  def restore_training
    render json: repository.restore
  end

  def starter_image
    return head :not_found unless Sketch::StarterImages::SHAPES.key?(params[:key])
    response.headers['X-Content-Type-Options'] = 'nosniff'
    send_data Sketch::StarterImages.new.png(params[:key]), type: 'image/png', disposition: 'inline'
  end

  def identify
    render json: repository.identify(params[:pixels])
  end

  def teach
    render json: repository.teach(params[:pixels], params[:label])
  end

  def sample
    path = repository.sample_path(params[:id])
    return head :not_found unless path
    response.headers['X-Content-Type-Options'] = 'nosniff'
    send_file path, type: 'image/png', disposition: 'inline'
  end

  private

  def repository = Sketch::Repository.new(Rails.configuration.x.sketch_storage)

  def invalid_input(error)
    render json: { error: error.message }, status: :unprocessable_entity
  end
end
