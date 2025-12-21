class MetricsController < ApplicationController
  before_action :set_metric, only: %i[ show edit update destroy ]

  # GET /metrics or /metrics.json
  def index
    @metrics = Metric.all
  end

  # GET /metrics/1 or /metrics/1.json
  def show
  end

  # GET /metrics/new
  def new
    @metric = Metric.new
  end

  # GET /metrics/1/edit
  def edit
  end

  # POST /metrics or /metrics.json
  def create
    @metric = Metric.new(metric_params)

    respond_to do |format|
      if @metric.save
        format.html { redirect_to @metric, notice: "Metric was successfully created." }
        format.json { render :show, status: :created, location: @metric }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @metric.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /metrics/1 or /metrics/1.json
  def update
    respond_to do |format|
      if @metric.update(metric_params)
        format.html { redirect_to @metric, notice: "Metric was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @metric }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @metric.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /metrics/1 or /metrics/1.json
  def destroy
    @metric.destroy!

    respond_to do |format|
      format.html { redirect_to metrics_path, notice: "Metric was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_metric
      @metric = Metric.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def metric_params
      params.expect(metric: [ :date, :pe, :pb, :mcap, :fundamentals, :stock_id ])
    end
end
