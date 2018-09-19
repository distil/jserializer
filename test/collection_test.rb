require "test_helper"

class CollectionTest < Minitest::Test
  Job = Struct.new(:id, :description, :applicants)
  Applicant = Struct.new(:id, :name)

  class ApplicantSerializer < Jserializer::Base
    attributes :id, :name
  end

  class JobSerializer < Jserializer::Base
    attributes :id, :description
    has_many :applicants, serializer: ApplicantSerializer
  end

  describe 'Collection' do
    it 'serializes an array of objects using single serializer' do
      jobs = create_jobs_with_applications(total_jobs: 10, total_applicants: 2)
      serializer = JobSerializer.new(jobs, is_collection: true)
      result = serializer.serializable_hash
      assert result.is_a?(Array)
      assert_equal(10, result.length)
      result.each { |job| assert_equal(2, job[:applicants].length) }
    end

    it 'serializes as collection by calling serializable_collection method' do
      jobs = create_jobs_with_applications(total_jobs: 10, total_applicants: 2)
      serializer = JobSerializer.new(jobs)
      result = serializer.serializable_collection
      assert result.is_a?(Array)
      assert_equal(10, result.length)
      result.each { |job| assert_equal(2, job[:applicants].length) }
    end

    it 'merges options into the final hash' do
      jobs = create_jobs_with_applications(total_jobs: 10, total_applicants: 2)
      options = {
        root: :jobs,
        is_collection: true,
        meta: { total_count: 100, page: 1, per_page: 10 },
        meta_key: :extra
      }
      serializer = JobSerializer.new(jobs, options)
      result = serializer.as_json
      assert_equal([:jobs, :extra], result.keys)
      assert_equal(options[:meta], result[:extra])
      assert_equal(10, result[:jobs].length)
      result[:jobs].each { |job| assert_equal(2, job[:applicants].length) }
    end

    def create_jobs_with_applications(total_jobs: 10, total_applicants: 2)
      applicants = (1..total_applicants).to_a.map do |id|
        Applicant.new(id, "applicant #{id}")
      end

      (1..total_jobs).to_a.map do |id|
        job = Job.new(id, "Job #{id}")
        job.applicants = applicants
        job
      end
    end
  end
end
