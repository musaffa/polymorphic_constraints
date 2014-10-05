require 'spec_helper'

describe 'polymorphic error reraise' do
  class DummyController < ApplicationController
    def polymorphic_record_not_found
      raise ActiveRecord::StatementInvalid, 'Polymorphic Constraints error. Polymorphic record not found.'
    end

    def polymorphic_reference_exists
      raise ActiveRecord::StatementInvalid, 'Polymorphic Constraints error. Polymorphic reference exists.'
    end

    def not_a_polymorphic_error
      raise ActiveRecord::StatementInvalid, 'Not a Polymorphic Constraints error.'
    end
  end

  Rails.application.routes.draw do
    # The priority is based upon order of creation: first created -> highest priority.
    # See how all your routes lay out with "rake routes".
    get '/polymorphic_record_not_found', to: 'dummy#polymorphic_record_not_found'
    get '/polymorphic_reference_exists', to: 'dummy#polymorphic_reference_exists'
    get '/not_a_polymorphic_error', to: 'dummy#not_a_polymorphic_error'
  end

  describe DummyController, type: :controller do
    context 'polymorphic record not found' do
      it 're-raises ActiveRecord::RecordNotFound properly' do
        expect { get :polymorphic_record_not_found }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'polymorphic reference exists' do
      it 're-raises ActiveRecord::InvalidForeignKey properly' do
        expect { get :polymorphic_reference_exists }.to raise_error(ActiveRecord::InvalidForeignKey)
      end
    end

    context 'not a polymorphic constraints error' do
      it 're-raises ActiveRecord::StatementInvalid properly' do
        expect { get :not_a_polymorphic_error }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
end
