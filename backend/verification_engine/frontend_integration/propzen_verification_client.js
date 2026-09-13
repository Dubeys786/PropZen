/**
 * PropZen GlobalVerificationEngine - Frontend API Client
 * Clean integration layer for the PropZen web platform and mobile web clients.
 */

class PropZenVerificationClient {
    /**
     * @param {Object} config
     * @param {string} [config.baseUrl='http://localhost:8000'] - Base URL of Verification Microservice
     * @param {string} [config.apiKey=''] - Verification API Key if authentication is enforced
     */
    constructor(config = {}) {
        this.baseUrl = (config.baseUrl || 'http://localhost:8000').replace(/\/+$/, '');
        this.apiKey = config.apiKey || '';
    }

    /**
     * Helper for standard JSON fetch requests
     */
    async _request(endpoint, options = {}) {
        const url = `${this.baseUrl}${endpoint}`;
        const headers = {
            'Accept': 'application/json',
            ...(options.headers || {}),
        };

        if (this.apiKey) {
            headers['X-API-Key'] = this.apiKey;
        }

        const response = await fetch(url, { ...options, headers });
        if (!response.ok) {
            let errDetail = 'Request failed';
            try {
                const errBody = await response.json();
                errDetail = errBody.detail || errBody.message || JSON.stringify(errBody);
            } catch (e) {
                errDetail = `${response.status} ${response.statusText}`;
            }
            throw new Error(`[PropZenVerification] ${errDetail}`);
        }
        return await response.json();
    }

    /**
     * Check verification service health
     * @returns {Promise<Object>}
     */
    async checkHealth() {
        return await this._request('/api/v1/verification/health');
    }

    /**
     * Initialize a new verification case
     * @param {Object} params
     * @param {string} [params.userId='anonymous_user']
     * @param {string} [params.propertyId]
     * @param {string} [params.documentType='GENERIC_PROPERTY_DOCUMENT']
     * @param {string} [params.notes]
     * @returns {Promise<Object>}
     */
    async createCase(params = {}) {
        return await this._request('/api/v1/verification/cases', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                user_id: params.userId || 'anonymous_user',
                property_id: params.propertyId || null,
                document_type: params.documentType || 'GENERIC_PROPERTY_DOCUMENT',
                notes: params.notes || null,
            }),
        });
    }

    /**
     * Upload a property document for verification
     * @param {string} caseId
     * @param {File|Blob} file
     * @param {string} [documentType]
     * @returns {Promise<Object>}
     */
    async uploadDocument(caseId, file, documentType = null) {
        const formData = new FormData();
        formData.append('file', file);
        if (documentType) {
            formData.append('document_type', documentType);
        }

        const url = `${this.baseUrl}/api/v1/verification/cases/${caseId}/documents`;
        const headers = {};
        if (this.apiKey) {
            headers['X-API-Key'] = this.apiKey;
        }

        const response = await fetch(url, {
            method: 'POST',
            headers,
            body: formData,
        });

        if (!response.ok) {
            const err = await response.json().catch(() => ({ detail: response.statusText }));
            throw new Error(`[PropZenVerification Upload] ${err.detail || 'Upload failed'}`);
        }
        return await response.json();
    }

    /**
     * Trigger AI extraction, consistency validation, and risk scoring
     * @param {string} caseId
     * @returns {Promise<Object>}
     */
    async analyzeCase(caseId) {
        return await this._request(`/api/v1/verification/cases/${caseId}/analyze`, {
            method: 'POST',
        });
    }

    /**
     * Retrieve case overview and current status
     * @param {string} caseId
     * @returns {Promise<Object>}
     */
    async getCase(caseId) {
        return await this._request(`/api/v1/verification/cases/${caseId}`);
    }

    /**
     * Retrieve specific findings and recommendations
     * @param {string} caseId
     * @returns {Promise<Array>}
     */
    async getFindings(caseId) {
        return await this._request(`/api/v1/verification/cases/${caseId}/findings`);
    }
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = { PropZenVerificationClient };
} else if (typeof window !== 'undefined') {
    window.PropZenVerificationClient = PropZenVerificationClient;
}
