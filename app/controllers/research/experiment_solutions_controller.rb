module Research
  class ExperimentSolutionsController < Research::BaseController
    def create
      experiment = Experiment.find(params[:experiment_id])

      exercise_slug = "#{params[:language]}-#{params[:part]}-#{%w{a b}.sample}"
      exercise = Exercise.find_by_slug!(exercise_slug)

      # Guard to ensure that someone doesn't try to access
      # a non-research solution through this method.
      raise "Incorrect exercise" unless exercise.track.research_track?

      solution = Research::CreateSolution.(
        current_user,
        experiment,
        exercise
      )

      redirect_to research_experiment_solution_path(solution)
    end

    def show
      @solution = current_user.research_experiment_solutions.find_by_uuid(params[:id])
      @exercise = @solution.exercise
      @track = Track.find_by(slug: @solution.language_slug)
      @editor_config = @track.try(&:editor_config)
      @syntax_highlighter_language = @track.try(&:syntax_highlighter_language)
    end

    def post_exercise_survey
      @solution = current_user.research_experiment_solutions.find_by_uuid(params[:id])
      @exercise = @solution.exercise
      render_modal("post_exercise_survey", "post_exercise_survey")
    end

    def submit
      solution = Research::ExperimentSolution.find_by(uuid: params[:id])
      solution.update!(difficulty_rating: params[:survey][:difficulty_rating])

      solution.submit!

      user_experiment = solution.user_experiment
      if user_experiment.survey_completed?
        redirect_to research_user_experiment_path(user_experiment)
      else
        redirect_to research_user_experiment_survey_path(user_experiment)
      end
    end
  end
end
