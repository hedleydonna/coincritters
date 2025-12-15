# Device Transfer Feature - Technical Specifications

## Overview

The Device Transfer feature allows users to temporarily upload their local data to the cloud server, then download it on a new device. After successful download, the data is automatically deleted from the server. This provides a solution for device migration while maintaining the local-first, privacy-focused architecture.

## Design Philosophy

- **Local-First**: Primary data storage remains on the device
- **Temporary Cloud Storage**: Data only stored in cloud during transfer window (7 days max)
- **No Account Required**: Uses transfer codes instead of user accounts
- **Privacy-Focused**: Data encrypted, auto-deleted after use
- **Cost-Effective**: Minimal server costs due to temporary storage

## User Experience Flow

### Export/Upload (Old Device)

1. User navigates to Settings → "Transfer to New Device"
2. User taps "Generate Transfer Code"
3. App exports all local data:
   - Monthly budgets
   - Expenses and expense templates
   - Income sources and income events
   - Payments
   - User preferences
4. Data is encrypted and uploaded to server
5. Server generates unique transfer code (format: `TRANSFER-XXXXXX-XXXXXX`)
6. User sees transfer code with expiration date (7 days)
7. User can copy code or view QR code

### Import/Download (New Device)

1. User installs app on new device
2. User sees "Restore from Transfer" option on initial setup
3. User enters transfer code (or scans QR code)
4. App validates code with server
5. App downloads encrypted data
6. App imports data into local database
7. Server marks transfer as "downloaded" and schedules deletion
8. User sees confirmation: "Transfer complete! Data deleted from server."

## Technical Architecture

### Backend Components

#### Database Schema

```ruby
# Migration: create_data_transfers.rb
class CreateDataTransfers < ActiveRecord::Migration[7.1]
  def change
    create_table :data_transfers do |t|
      t.string :transfer_code, null: false, index: { unique: true }
      t.text :encrypted_data, null: false  # Encrypted JSON/SQLite dump
      t.datetime :expires_at, null: false
      t.datetime :downloaded_at
      t.string :ip_address  # For security/rate limiting
      t.integer :download_count, default: 0  # Track download attempts
      t.timestamps
    end
    
    add_index :data_transfers, :expires_at
    add_index :data_transfers, :downloaded_at
  end
end
```

#### Model

```ruby
# app/models/data_transfer.rb
class DataTransfer < ApplicationRecord
  # Generate unique transfer code
  before_create :generate_transfer_code
  before_create :set_expiration
  
  # Validations
  validates :transfer_code, presence: true, uniqueness: true
  validates :encrypted_data, presence: true
  validates :expires_at, presence: true
  
  # Scopes
  scope :active, -> { where(downloaded_at: nil).where("expires_at > ?", Time.current) }
  scope :expired, -> { where("expires_at < ?", Time.current) }
  scope :downloaded, -> { where.not(downloaded_at: nil) }
  
  # Check if transfer is still valid
  def valid?
    downloaded_at.nil? && expires_at > Time.current
  end
  
  # Mark as downloaded
  def mark_downloaded!
    update!(downloaded_at: Time.current)
  end
  
  private
  
  def generate_transfer_code
    loop do
      code = "TRANSFER-#{SecureRandom.alphanumeric(6).upcase}-#{SecureRandom.alphanumeric(6).upcase}"
      break self.transfer_code = code unless DataTransfer.exists?(transfer_code: code)
    end
  end
  
  def set_expiration
    self.expires_at ||= 7.days.from_now
  end
end
```

#### Controller

```ruby
# app/controllers/data_transfers_controller.rb
class DataTransfersController < ApplicationController
  # No authentication required - uses transfer codes instead
  
  # Rate limiting
  before_action :rate_limit_transfer_creation, only: [:create]
  
  # POST /data_transfers
  # Creates a new transfer with encrypted data
  def create
    @transfer = DataTransfer.new(
      encrypted_data: params[:encrypted_data],
      ip_address: request.remote_ip
    )
    
    if @transfer.save
      render json: {
        transfer_code: @transfer.transfer_code,
        expires_at: @transfer.expires_at.iso8601,
        message: "Transfer code created. Valid for 7 days."
      }, status: :created
    else
      render json: { errors: @transfer.errors.full_messages }, status: :unprocessable_entity
    end
  end
  
  # GET /data_transfers/:transfer_code
  # Downloads data by transfer code
  def show
    @transfer = DataTransfer.find_by(transfer_code: params[:transfer_code])
    
    unless @transfer
      render json: { error: "Transfer code not found" }, status: :not_found
      return
    end
    
    unless @transfer.valid?
      render json: { error: "Transfer code expired or already used" }, status: :gone
      return
    end
    
    # Increment download count
    @transfer.increment!(:download_count)
    
    # Mark as downloaded (will be deleted by cleanup job)
    @transfer.mark_downloaded!
    
    render json: {
      encrypted_data: @transfer.encrypted_data,
      created_at: @transfer.created_at.iso8601,
      message: "Data downloaded. Transfer code is now invalid."
    }
  end
  
  # GET /data_transfers/:transfer_code/status
  # Check if transfer code is valid (without downloading)
  def status
    @transfer = DataTransfer.find_by(transfer_code: params[:transfer_code])
    
    if @transfer&.valid?
      render json: {
        valid: true,
        expires_at: @transfer.expires_at.iso8601,
        days_remaining: ((@transfer.expires_at - Time.current) / 1.day).ceil
      }
    else
      render json: { valid: false, error: "Transfer code not found or expired" }
    end
  end
  
  private
  
  def rate_limit_transfer_creation
    # Limit to 5 transfers per IP per hour
    recent_transfers = DataTransfer.where(
      ip_address: request.remote_ip,
      created_at: 1.hour.ago..Time.current
    ).count
    
    if recent_transfers >= 5
      render json: { error: "Too many transfer requests. Please try again later." }, 
             status: :too_many_requests
    end
  end
end
```

#### Routes

```ruby
# config/routes.rb
# Add to public routes (no authentication required)
resources :data_transfers, only: [:create, :show] do
  member do
    get :status
  end
end
```

#### Cleanup Job

```ruby
# app/jobs/data_transfer_cleanup_job.rb
class DataTransferCleanupJob < ApplicationJob
  queue_as :default
  
  def perform
    # Delete expired transfers
    expired_count = DataTransfer.expired.delete_all
    
    # Delete downloaded transfers older than 1 day
    old_downloaded = DataTransfer.downloaded
                                  .where("downloaded_at < ?", 1.day.ago)
                                  .delete_all
    
    Rails.logger.info "Cleaned up #{expired_count} expired transfers and #{old_downloaded} old downloaded transfers"
  end
end

# Schedule in config/schedule.rb (if using whenever gem)
# Or use Rails' built-in job scheduling
# every 1.day, at: '2:00 am' do
#   runner "DataTransferCleanupJob.perform_later"
# end
```

### Frontend Components (Mobile App)

#### Data Export Service

```javascript
// services/DataExportService.js
class DataExportService {
  async exportAllData() {
    // Export all data from local database
    const data = {
      version: "1.0",
      exported_at: new Date().toISOString(),
      monthly_budgets: await this.exportMonthlyBudgets(),
      expenses: await this.exportExpenses(),
      expense_templates: await this.exportExpenseTemplates(),
      income_templates: await this.exportIncomeTemplates(),
      income_events: await this.exportIncomeEvents(),
      payments: await this.exportPayments(),
      user_preferences: await this.exportUserPreferences()
    };
    
    // Convert to JSON string
    const jsonString = JSON.stringify(data);
    
    // Compress (optional, using pako or similar)
    // const compressed = pako.deflate(jsonString);
    
    return jsonString;
  }
  
  async exportMonthlyBudgets() {
    // Query local database for all monthly budgets
    // Return array of budget objects
  }
  
  // Similar methods for other data types...
}
```

#### Data Import Service

```javascript
// services/DataImportService.js
class DataImportService {
  async importData(jsonString) {
    try {
      const data = JSON.parse(jsonString);
      
      // Validate version compatibility
      if (!this.isCompatibleVersion(data.version)) {
        throw new Error("Data version incompatible");
      }
      
      // Import in transaction
      await this.beginTransaction();
      
      try {
        await this.importMonthlyBudgets(data.monthly_budgets);
        await this.importExpenses(data.expenses);
        await this.importExpenseTemplates(data.expense_templates);
        await this.importIncomeTemplates(data.income_templates);
        await this.importIncomeEvents(data.income_events);
        await this.importPayments(data.payments);
        await this.importUserPreferences(data.user_preferences);
        
        await this.commitTransaction();
        return { success: true };
      } catch (error) {
        await this.rollbackTransaction();
        throw error;
      }
    } catch (error) {
      throw new Error(`Import failed: ${error.message}`);
    }
  }
  
  isCompatibleVersion(version) {
    // Check if data version is compatible with current app version
    return version === "1.0"; // Update as app evolves
  }
  
  // Import methods for each data type...
}
```

#### Transfer API Client

```javascript
// services/TransferAPIClient.js
class TransferAPIClient {
  constructor(baseURL) {
    this.baseURL = baseURL || "https://your-app.onrender.com";
  }
  
  async createTransfer(encryptedData) {
    const response = await fetch(`${this.baseURL}/data_transfers`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        encrypted_data: encryptedData
      })
    });
    
    if (!response.ok) {
      throw new Error(`Transfer creation failed: ${response.statusText}`);
    }
    
    return await response.json();
  }
  
  async downloadTransfer(transferCode) {
    const response = await fetch(`${this.baseURL}/data_transfers/${transferCode}`);
    
    if (response.status === 404) {
      throw new Error("Transfer code not found");
    }
    
    if (response.status === 410) {
      throw new Error("Transfer code expired or already used");
    }
    
    if (!response.ok) {
      throw new Error(`Download failed: ${response.statusText}`);
    }
    
    return await response.json();
  }
  
  async checkTransferStatus(transferCode) {
    const response = await fetch(`${this.baseURL}/data_transfers/${transferCode}/status`);
    return await response.json();
  }
}
```

#### Encryption Service

```javascript
// services/EncryptionService.js
class EncryptionService {
  // Simple encryption using Web Crypto API
  async encrypt(data, password) {
    // Generate key from password
    const key = await this.deriveKey(password);
    
    // Encrypt data
    const encrypted = await crypto.subtle.encrypt(
      { name: "AES-GCM", iv: this.generateIV() },
      key,
      new TextEncoder().encode(data)
    );
    
    return this.arrayBufferToBase64(encrypted);
  }
  
  async decrypt(encryptedData, password) {
    // Decrypt using password-derived key
    const key = await this.deriveKey(password);
    const decrypted = await crypto.subtle.decrypt(
      { name: "AES-GCM", iv: this.getIV(encryptedData) },
      key,
      this.base64ToArrayBuffer(encryptedData)
    );
    
    return new TextDecoder().decode(decrypted);
  }
  
  // Alternative: Use transfer code as encryption key
  // This way, only someone with the code can decrypt
  async encryptWithCode(data, transferCode) {
    return await this.encrypt(data, transferCode);
  }
}
```

## Security Considerations

### 1. Transfer Code Generation
- Use cryptographically secure random generation
- Format: `TRANSFER-XXXXXX-XXXXXX` (12 alphanumeric characters)
- Ensure uniqueness in database
- Case-insensitive matching

### 2. Data Encryption
- Encrypt data before upload
- Use AES-256-GCM encryption
- Option A: Use transfer code as encryption key (simpler, code = key)
- Option B: Generate separate encryption key, encrypt with transfer code (more secure)
- Never store encryption keys on server

### 3. Rate Limiting
- Limit transfer creation: 5 per IP per hour
- Limit download attempts: 10 per transfer code
- Log suspicious activity
- Consider CAPTCHA for repeated failures

### 4. Data Validation
- Validate data structure on import
- Check version compatibility
- Sanitize imported data
- Handle malformed data gracefully

### 5. Privacy
- No user accounts required
- No personal information stored with transfer
- Auto-delete after download or expiration
- Log minimal information (IP, timestamps only)

## Error Handling

### Export Errors
- **Network failure**: Retry with exponential backoff
- **Upload timeout**: Show error, allow retry
- **Data too large**: Compress or split into chunks
- **Encryption failure**: Show clear error message

### Import Errors
- **Invalid code**: Clear error message
- **Expired code**: Suggest generating new transfer
- **Download failure**: Allow retry (if not yet marked as downloaded)
- **Import failure**: Rollback transaction, show error
- **Version mismatch**: Show compatibility error, suggest app update

### Server Errors
- **Transfer not found**: 404 with clear message
- **Transfer expired**: 410 Gone with expiration date
- **Transfer already used**: 410 Gone with clear message
- **Rate limit exceeded**: 429 Too Many Requests

## Data Format Specification

### Export JSON Structure

```json
{
  "version": "1.0",
  "exported_at": "2025-12-15T10:30:00Z",
  "app_version": "1.0.0",
  "monthly_budgets": [
    {
      "month_year": "2025-12",
      "total_actual_income": 5000.00,
      "bank_balance": null,
      "created_at": "2025-12-01T00:00:00Z",
      "updated_at": "2025-12-15T10:00:00Z"
    }
  ],
  "expense_templates": [
    {
      "name": "Rent",
      "default_amount": 1200.00,
      "auto_create": true,
      "frequency": "monthly",
      "due_date": "2025-12-01",
      "is_active": true
    }
  ],
  "expenses": [
    {
      "name": "Rent",
      "allotted_amount": 1200.00,
      "monthly_budget_id": 1,
      "expense_template_id": 1
    }
  ],
  "income_templates": [
    {
      "name": "Salary",
      "frequency": "monthly",
      "estimated_amount": 5000.00,
      "auto_create": true,
      "due_date": "2025-12-01",
      "last_payment_to_next_month": false,
      "active": true
    }
  ],
  "income_events": [
    {
      "income_id": 1,
      "custom_label": null,
      "month_year": "2025-12",
      "apply_to_next_month": false,
      "received_on": "2025-12-01",
      "actual_amount": 5000.00,
      "notes": null
    }
  ],
  "payments": [
    {
      "expense_id": 1,
      "amount": 1200.00,
      "spent_on": "2025-12-01",
      "notes": null
    }
  ],
  "user_preferences": {
    "currency": "USD",
    "date_format": "MM/DD/YYYY"
  }
}
```

## Cost Analysis

### Storage Costs
- Average data size per user: ~50-200 KB (compressed)
- Storage duration: 7 days maximum
- Estimated users: 100 transfers/month
- Storage needed: ~20 MB peak
- **Cost: <$0.10/month** (Render free tier includes 750 hours)

### Bandwidth Costs
- Upload: ~50-200 KB per transfer
- Download: ~50-200 KB per transfer
- 100 transfers/month = ~20-40 MB total
- **Cost: <$0.05/month** (most hosting includes generous bandwidth)

### Database Costs
- Temporary records, auto-deleted
- Minimal index overhead
- **Cost: Negligible** (part of existing database)

### Total Estimated Cost
- **<$1/month** for hundreds of transfers
- Scales linearly but remains very low

## Implementation Phases

### Phase 1: Basic Transfer (MVP)
- Simple upload/download endpoint
- Basic transfer code generation
- Manual cleanup (cron job or manual deletion)
- No encryption (add in Phase 2)
- Basic error handling

**Timeline**: 1-2 weeks

### Phase 2: Enhanced Security
- Add encryption
- Rate limiting
- Automatic cleanup job
- Better error messages
- Transfer status checking

**Timeline**: 1 week

### Phase 3: User Experience
- QR code generation for transfer codes
- Progress indicators
- Transfer history (optional, local only)
- Better UI/UX
- Offline queue for uploads

**Timeline**: 1-2 weeks

### Phase 4: Advanced Features (Future)
- Multiple device support
- Partial transfers (selective data)
- Conflict resolution
- Transfer verification (checksums)
- Analytics (optional, privacy-respecting)

**Timeline**: 2-3 weeks

## Testing Strategy

### Unit Tests
- Transfer code generation uniqueness
- Expiration logic
- Encryption/decryption
- Data export/import
- Validation logic

### Integration Tests
- Full transfer flow (create → download → verify deletion)
- Error scenarios (expired, invalid code, network failure)
- Rate limiting
- Cleanup job

### Security Tests
- Transfer code brute force attempts
- Data encryption verification
- Rate limiting effectiveness
- SQL injection prevention
- XSS prevention

## Monitoring and Maintenance

### Metrics to Track
- Number of transfers created per day
- Average data size
- Transfer success rate
- Cleanup job execution
- Error rates by type

### Alerts
- High error rate (>5%)
- Cleanup job failures
- Unusual transfer patterns (potential abuse)
- Storage usage spikes

### Maintenance Tasks
- Regular cleanup job monitoring
- Review and update encryption if needed
- Monitor costs
- Update data format version as app evolves

## Future Considerations

### If Demand Grows
- Consider permanent cloud sync option (premium feature)
- Add user accounts for easier multi-device access
- Implement incremental sync
- Add sharing features (optional)

### If Costs Become Issue
- Implement transfer limits per user
- Add premium tier for unlimited transfers
- Optimize data compression
- Consider alternative storage solutions

## Migration Path from Current Architecture

### Current State
- Rails web app with PostgreSQL
- User authentication via Devise
- All data in cloud database

### Transition to Local-First
1. **Phase 1**: Keep current architecture, add transfer feature
2. **Phase 2**: Build mobile app with local storage
3. **Phase 3**: Add transfer feature to mobile app
4. **Phase 4**: (Optional) Migrate web app to local storage with transfer

### Backward Compatibility
- Web app can continue using cloud database
- Mobile app uses local storage
- Transfer feature bridges the gap
- Users can choose their preferred approach

## Open Questions

1. **Encryption Key Management**: Use transfer code as key, or separate key?
   - Recommendation: Start with transfer code as key (simpler)
   - Upgrade to separate key if security concerns arise

2. **Data Format Versioning**: How to handle app updates?
   - Include version in export
   - Check compatibility on import
   - Provide migration scripts if needed

3. **Transfer Code Display**: QR code or text only?
   - Start with text (simpler)
   - Add QR code in Phase 3

4. **Multiple Downloads**: Allow re-download before expiration?
   - Recommendation: Single download only (more secure)
   - Or allow re-download within 24 hours

5. **Partial Transfers**: Allow users to select what to transfer?
   - Start with full transfer only
   - Add selective transfer in Phase 4 if requested

## Conclusion

The Device Transfer feature provides an elegant solution for device migration while maintaining the local-first, privacy-focused architecture. It solves the user's need to transfer data to a new device without requiring ongoing cloud storage or user accounts. The temporary nature keeps costs minimal while providing the necessary functionality.

The implementation can be done incrementally, starting with a basic version and enhancing over time based on user feedback and needs.

---

**Last Updated**: December 2025
**Status**: Planning/Design Phase
**Priority**: Medium (can be implemented after core app features are stable)

