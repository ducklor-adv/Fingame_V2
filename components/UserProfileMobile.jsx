import React, { useState, useEffect } from "react";

// ---------- Types ----------

type UserProfile = {
  id: string;
  worldId: string;
  username: string;
  email?: string;
  phone?: string;
  firstName?: string;
  lastName?: string;
  avatarUrl?: string;
  profileImageFilename?: string;
  bio?: string;
  location?: {
    city?: string;
    country?: string;
    coordinates?: { lat: number; lng: number };
  };
  preferredCurrency: string;
  language: string;
  isVerified: boolean;
  verificationLevel: number;
  trustScore: number;
  totalSales: number;
  totalPurchases: number;

  // ACF Info
  runNumber: number;
  level: number;
  childCount: number;
  maxChildren: number;
  acfAccepting: boolean;

  // Finpoint
  ownFinpoint: number;
  totalFinpoint: number;
  maxNetwork: number;

  // Address
  addressNumber?: string;
  addressStreet?: string;
  addressDistrict?: string;
  addressProvince?: string;
  addressPostalCode?: string;

  // Metadata
  createdAt: number;
  updatedAt: number;
  lastLogin?: string;
  inviter?: {
    id?: string;
    username?: string;
    firstName?: string;
    lastName?: string;
    worldId?: string;
  } | null;
  parent?: {
    id?: string;
    username?: string;
    firstName?: string;
    lastName?: string;
    worldId?: string;
  } | null;
};

type UserProfileProps = {
  userId: string;
  onUpdate?: (profile: Partial<UserProfile>) => void;
};

// ---------- User Profile Component (Mobile-First) ----------

export const UserProfile: React.FC<UserProfileProps> = ({
  userId,
  onUpdate
}) => {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [editForm, setEditForm] = useState<Partial<UserProfile>>({});
  const [activeTab, setActiveTab] = useState<'info' | 'address' | 'settings'>('info');
  const [uploadingAvatar, setUploadingAvatar] = useState(false);

  // Load user profile
  useEffect(() => {
    loadProfile();
  }, [userId]);

  const loadProfile = async () => {
    try {
      setLoading(true);
      // TODO: Replace with actual API call
      const response = await fetch(`/api/users/${userId}`);
      const data = await response.json();
      setProfile(data);
      setEditForm(data);
    } catch (error) {
      console.error("Failed to load profile:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = () => {
    setEditing(true);
  };

  const handleCancel = () => {
    setEditing(false);
    setEditForm(profile || {});
  };

  const handleSave = async () => {
    try {
      // TODO: Replace with actual API call
      const response = await fetch(`/api/users/${userId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(editForm),
      });
      const updated = await response.json();
      setProfile(updated);
      setEditing(false);
      onUpdate?.(updated);
    } catch (error) {
      console.error("Failed to save profile:", error);
    }
  };

  const handleChange = (field: keyof UserProfile, value: any) => {
    setEditForm((prev) => ({ ...prev, [field]: value }));
  };

  const handleAvatarUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      setUploadingAvatar(true);

      const formData = new FormData();
      formData.append('avatar', file);

      const response = await fetch(`/api/users/${userId}/upload-avatar`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Failed to upload avatar');
      }

      const data = await response.json();
      setProfile(data.profile);
      setEditForm(data.profile);
      onUpdate?.(data.profile);
    } catch (error) {
      console.error('Failed to upload avatar:', error);
      alert('ไม่สามารถอัปโหลดรูปภาพได้ กรุณาลองใหม่');
    } finally {
      setUploadingAvatar(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center px-4">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin mx-auto mb-3"></div>
          <div className="text-slate-400 text-sm">กำลังโหลด...</div>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center px-4">
        <div className="text-center">
          <div className="text-red-400 text-lg mb-2">⚠️</div>
          <div className="text-red-400">ไม่พบข้อมูลผู้ใช้</div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 pb-20">
      {/* HEADER - Fixed on mobile */}
      <header className="sticky top-0 z-30 border-b border-slate-800 bg-slate-900/95 backdrop-blur-lg">
        <div className="px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 sm:w-10 sm:h-10 rounded-full bg-emerald-400/20 border border-emerald-400/50 flex items-center justify-center text-xs sm:text-sm font-bold text-emerald-300">
              FG
            </div>
              <div>
              <h1 className="text-sm sm:text-base font-semibold">โปรไฟล์</h1>
              <p className="text-xs text-slate-400">{profile.worldId}</p>

              {/* New small details under world id */}
              <div className="mt-1 text-xs text-slate-300">
                <div>{profile.username}</div>
                {(profile.firstName || profile.lastName) && (
                  <div className="text-slate-400">{profile.firstName} {profile.lastName}</div>
                )}
                <div className="mt-1 text-xs text-slate-400">
                  {profile.inviter ? (
                    <span>ผู้แนะนำ: {profile.inviter.username || profile.inviter.fullName || `${profile.inviter.firstName || ''} ${profile.inviter.lastName || ''}`.trim() || profile.inviter.worldId}</span>
                  ) : (
                    <span>ผู้แนะนำ: —</span>
                  )}
                </div>
                <div className="text-xs text-slate-400">
                  {profile.parent ? (
                    <span>ผู้ปกครอง ACF: {profile.parent.worldId || profile.parent.username || profile.parent.fullName || `${profile.parent.firstName || ''} ${profile.parent.lastName || ''}`.trim()}</span>
                  ) : (
                    <span>ผู้ปกครอง ACF: —</span>
                  )}
                </div>
              </div>
            </div>
          </div>

          <div className="flex gap-2">
            {!editing ? (
              <button
                onClick={handleEdit}
                className="px-3 py-1.5 sm:px-4 sm:py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-xs sm:text-sm font-medium transition-colors active:scale-95"
              >
                แก้ไข
              </button>
            ) : (
              <>
                <button
                  onClick={handleCancel}
                  className="px-3 py-1.5 sm:px-4 sm:py-2 bg-slate-700 hover:bg-slate-600 rounded-lg text-xs sm:text-sm font-medium transition-colors active:scale-95"
                >
                  ยกเลิก
                </button>
                <button
                  onClick={handleSave}
                  className="px-3 py-1.5 sm:px-4 sm:py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-xs sm:text-sm font-medium transition-colors active:scale-95"
                >
                  บันทึก
                </button>
              </>
            )}
          </div>
        </div>
      </header>

      {/* PROFILE HEADER CARD - Mobile optimized */}
      <section className="bg-slate-900/60 border-b border-slate-800">
        {/* Cover gradient - shorter on mobile */}
        <div className="h-24 sm:h-32 bg-gradient-to-r from-emerald-600 via-teal-600 to-cyan-600"></div>

        <div className="px-4 pb-4">
          <div className="flex flex-col sm:flex-row items-center sm:items-end gap-4 -mt-12 sm:-mt-16">
            {/* Avatar */}
            <div className="relative flex-shrink-0 group">
              <div className="w-24 h-24 sm:w-32 sm:h-32 rounded-full border-4 border-slate-900 bg-slate-800 flex items-center justify-center text-3xl sm:text-4xl overflow-hidden">
                {profile.avatarUrl ? (
                  <img src={profile.avatarUrl} alt={profile.username} className="w-full h-full object-cover" />
                ) : (
                  <span>👤</span>
                )}
                {uploadingAvatar && (
                  <div className="absolute inset-0 bg-slate-900/80 flex items-center justify-center">
                    <div className="w-8 h-8 border-4 border-emerald-500 border-t-transparent rounded-full animate-spin"></div>
                  </div>
                )}
              </div>
              {profile.isVerified && (
                <div className="absolute bottom-0 right-0 w-8 h-8 sm:w-10 sm:h-10 bg-emerald-500 rounded-full border-4 border-slate-900 flex items-center justify-center text-sm">
                  ✓
                </div>
              )}
              {/* Upload button - visible on mobile, hover on desktop */}
              <label className="absolute inset-0 rounded-full cursor-pointer opacity-0 active:opacity-100 sm:group-hover:opacity-100 transition-opacity">
                <div className="w-full h-full rounded-full bg-slate-900/70 flex flex-col items-center justify-center">
                  <span className="text-2xl sm:text-3xl">📷</span>
                  <span className="text-white text-xs sm:text-sm font-medium mt-1">เปลี่ยนรูป</span>
                </div>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleAvatarUpload}
                  className="hidden"
                  disabled={uploadingAvatar}
                />
              </label>
              {/* Mobile: Tap to upload button */}
              <button
                onClick={() => document.getElementById('mobile-avatar-upload')?.click()}
                className="absolute -bottom-2 right-0 sm:hidden w-10 h-10 bg-emerald-600 rounded-full border-4 border-slate-900 flex items-center justify-center text-lg shadow-lg active:scale-95 transition-transform"
                disabled={uploadingAvatar}
              >
                📷
              </button>
              <input
                id="mobile-avatar-upload"
                type="file"
                accept="image/*"
                onChange={handleAvatarUpload}
                className="hidden"
                disabled={uploadingAvatar}
              />
            </div>

            {/* User Info - centered on mobile */}
            <div className="flex-1 text-center sm:text-left pb-2">
                <div className="flex flex-col sm:flex-row items-center gap-2 sm:gap-3">
                <h2 className="text-xl sm:text-2xl font-bold">{profile.username}</h2>
                </div>
              {(profile.firstName || profile.lastName) && (
                <p className="text-slate-400 mt-1 text-sm">
                  {profile.firstName} {profile.lastName}
                </p>
              )}
                <div className="flex flex-wrap items-center justify-center sm:justify-start gap-2 sm:gap-4 mt-2 text-xs sm:text-sm text-slate-400">
                <span>Trust: {profile.trustScore.toFixed(1)}</span>
                <span className="hidden sm:inline">•</span>
                <span className="hidden sm:inline">
                  {new Date(profile.createdAt).toLocaleDateString('th-TH')}
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* STATS ROW - Mobile horizontal scroll */}
      <section className="border-b border-slate-800 bg-slate-900/40">
        <div className="px-4 py-4 overflow-x-auto">
          <div className="flex gap-3 min-w-max sm:grid sm:grid-cols-3 sm:min-w-0">
            {/* Sales */}
            <div className="flex-shrink-0 w-32 sm:w-auto bg-slate-800/50 rounded-xl px-4 py-3 text-center border border-slate-700/50">
              <div className="text-xs text-slate-400 mb-1">ยอดขาย</div>
              <div className="text-lg sm:text-xl font-bold text-emerald-300">{profile.totalSales}</div>
            </div>

            {/* Purchases */}
            <div className="flex-shrink-0 w-32 sm:w-auto bg-slate-800/50 rounded-xl px-4 py-3 text-center border border-slate-700/50">
              <div className="text-xs text-slate-400 mb-1">ยอดซื้อ</div>
              <div className="text-lg sm:text-xl font-bold text-cyan-300">{profile.totalPurchases}</div>
            </div>

            {/* ACF Status */}
            <div className="flex-shrink-0 w-32 sm:w-auto bg-slate-800/50 rounded-xl px-4 py-3 text-center border border-slate-700/50">
              <div className="text-xs text-slate-400 mb-1">ACF</div>
              <div className={`text-lg sm:text-xl font-bold ${profile.acfAccepting ? 'text-emerald-300' : 'text-red-300'}`}>
                {profile.childCount}/{profile.maxChildren}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* FINPOINT CARD - Prominent on mobile */}
      <section className="px-4 py-4 bg-gradient-to-br from-emerald-900/20 to-teal-900/20">
        <div className="bg-gradient-to-br from-emerald-900/60 to-teal-900/60 border border-emerald-700/50 rounded-2xl p-4 sm:p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm uppercase tracking-wide text-emerald-300 font-semibold">Finpoint</h3>
            <div className="w-8 h-8 bg-emerald-400/20 rounded-full flex items-center justify-center">
              💎
            </div>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <div className="text-xs text-slate-400 mb-1">Own FP</div>
              <div className="text-xl sm:text-2xl font-bold text-emerald-300">
                {profile.ownFinpoint.toLocaleString()}
              </div>
            </div>
            <div>
              <div className="text-xs text-slate-400 mb-1">Total FP</div>
              <div className="text-xl sm:text-2xl font-semibold text-teal-300">
                {profile.totalFinpoint.toLocaleString()}
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* TAB NAVIGATION - Mobile friendly */}
      <nav className="sticky top-[57px] sm:top-[65px] z-20 bg-slate-900/95 backdrop-blur-lg border-b border-slate-800">
        <div className="flex">
          <button
            onClick={() => setActiveTab('info')}
            className={`flex-1 px-4 py-3 text-sm font-medium transition-colors relative ${
              activeTab === 'info'
                ? 'text-emerald-300'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            ข้อมูลส่วนตัว
            {activeTab === 'info' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-emerald-500"></div>
            )}
          </button>
          <button
            onClick={() => setActiveTab('address')}
            className={`flex-1 px-4 py-3 text-sm font-medium transition-colors relative ${
              activeTab === 'address'
                ? 'text-emerald-300'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            ที่อยู่
            {activeTab === 'address' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-emerald-500"></div>
            )}
          </button>
          <button
            onClick={() => setActiveTab('settings')}
            className={`flex-1 px-4 py-3 text-sm font-medium transition-colors relative ${
              activeTab === 'settings'
                ? 'text-emerald-300'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            ตั้งค่า
            {activeTab === 'settings' && (
              <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-emerald-500"></div>
            )}
          </button>
        </div>
      </nav>

      {/* CONTENT SECTIONS */}
      <main className="px-4 py-4 space-y-4">
        {/* Personal Information */}
        {activeTab === 'info' && (
          <div className="space-y-4">
            <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 sm:p-6">
              <h3 className="text-base sm:text-lg font-semibold mb-4 flex items-center gap-2">
                <span>👤</span>
                ข้อมูลส่วนตัว
              </h3>

              <div className="space-y-4">
                <InputField
                  label="ชื่อจริง"
                  value={editing ? editForm.firstName : profile.firstName}
                  onChange={(v) => handleChange("firstName", v)}
                  editing={editing}
                />
                <InputField
                  label="นามสกุล"
                  value={editing ? editForm.lastName : profile.lastName}
                  onChange={(v) => handleChange("lastName", v)}
                  editing={editing}
                />
                <InputField
                  label="อีเมล"
                  value={editing ? editForm.email : profile.email}
                  onChange={(v) => handleChange("email", v)}
                  editing={editing}
                  type="email"
                />
                <InputField
                  label="โทรศัพท์"
                  value={editing ? editForm.phone : profile.phone}
                  onChange={(v) => handleChange("phone", v)}
                  editing={editing}
                  type="tel"
                />
                <TextAreaField
                  label="ประวัติส่วนตัว"
                  value={editing ? editForm.bio : profile.bio}
                  onChange={(v) => handleChange("bio", v)}
                  editing={editing}
                  rows={3}
                />
              </div>
            </div>

            {/* Verification Status */}
            <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 sm:p-6">
              <h3 className="text-base sm:text-lg font-semibold mb-4 flex items-center gap-2">
                <span>✓</span>
                การยืนยันตัวตน
              </h3>

              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-slate-400">สถานะ</span>
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                    profile.isVerified
                      ? 'bg-emerald-500/20 text-emerald-300'
                      : 'bg-slate-700 text-slate-400'
                  }`}>
                    {profile.isVerified ? 'ยืนยันแล้ว' : 'ยังไม่ได้ยืนยัน'}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-slate-400">ระดับ</span>
                  <span className="text-sm font-medium">
                    {["ไม่ได้ยืนยัน", "โทรศัพท์", "อีเมล", "World ID", "เต็มรูปแบบ"][profile.verificationLevel]}
                  </span>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Address Information */}
        {activeTab === 'address' && (
          <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 sm:p-6">
            <h3 className="text-base sm:text-lg font-semibold mb-4 flex items-center gap-2">
              <span>📍</span>
              ที่อยู่
            </h3>

            <div className="space-y-4">
              <InputField
                label="บ้านเลขที่"
                value={editing ? editForm.addressNumber : profile.addressNumber}
                onChange={(v) => handleChange("addressNumber", v)}
                editing={editing}
              />
              <InputField
                label="ถนน"
                value={editing ? editForm.addressStreet : profile.addressStreet}
                onChange={(v) => handleChange("addressStreet", v)}
                editing={editing}
              />
              <InputField
                label="แขวง/ตำบล"
                value={editing ? editForm.addressDistrict : profile.addressDistrict}
                onChange={(v) => handleChange("addressDistrict", v)}
                editing={editing}
              />
              <InputField
                label="จังหวัด"
                value={editing ? editForm.addressProvince : profile.addressProvince}
                onChange={(v) => handleChange("addressProvince", v)}
                editing={editing}
              />
              <InputField
                label="รหัสไปรษณีย์"
                value={editing ? editForm.addressPostalCode : profile.addressPostalCode}
                onChange={(v) => handleChange("addressPostalCode", v)}
                editing={editing}
              />
            </div>
          </div>
        )}

        {/* Settings */}
        {activeTab === 'settings' && (
          <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-4 sm:p-6">
            <h3 className="text-base sm:text-lg font-semibold mb-4 flex items-center gap-2">
              <span>⚙️</span>
              การตั้งค่า
            </h3>

            <div className="space-y-4">
              <SelectField
                label="สกุลเงินที่ต้องการ"
                value={editing ? editForm.preferredCurrency : profile.preferredCurrency}
                onChange={(v) => handleChange("preferredCurrency", v)}
                editing={editing}
                options={[
                  { value: "THB", label: "THB - บาทไทย" },
                  { value: "USD", label: "USD - ดอลลาร์สหรัฐ" },
                  { value: "EUR", label: "EUR - ยูโร" },
                ]}
              />
              <SelectField
                label="ภาษา"
                value={editing ? editForm.language : profile.language}
                onChange={(v) => handleChange("language", v)}
                editing={editing}
                options={[
                  { value: "th", label: "ไทย" },
                  { value: "en", label: "English" },
                ]}
              />
            </div>
          </div>
        )}
      </main>
    </div>
  );
};

// ---------- Helper Components ----------

type InputFieldProps = {
  label: string;
  value?: string;
  onChange?: (value: string) => void;
  editing: boolean;
  type?: string;
};

const InputField: React.FC<InputFieldProps> = ({
  label,
  value,
  onChange,
  editing,
  type = "text"
}) => {
  return (
    <div>
      <label className="block text-xs sm:text-sm text-slate-400 mb-2">{label}</label>
      {editing ? (
        <input
          type={type}
          value={value || ""}
          onChange={(e) => onChange?.(e.target.value)}
          className="w-full px-3 py-2.5 sm:py-2 bg-slate-800 border border-slate-700 rounded-lg text-slate-100 text-sm focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition-colors"
        />
      ) : (
        <div className="px-3 py-2.5 sm:py-2 text-slate-200 text-sm">
          {value || <span className="text-slate-600">-</span>}
        </div>
      )}
    </div>
  );
};

type TextAreaFieldProps = {
  label: string;
  value?: string;
  onChange?: (value: string) => void;
  editing: boolean;
  rows?: number;
};

const TextAreaField: React.FC<TextAreaFieldProps> = ({
  label,
  value,
  onChange,
  editing,
  rows = 4
}) => {
  return (
    <div>
      <label className="block text-xs sm:text-sm text-slate-400 mb-2">{label}</label>
      {editing ? (
        <textarea
          value={value || ""}
          onChange={(e) => onChange?.(e.target.value)}
          rows={rows}
          className="w-full px-3 py-2.5 sm:py-2 bg-slate-800 border border-slate-700 rounded-lg text-slate-100 text-sm focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition-colors resize-none"
        />
      ) : (
        <div className="px-3 py-2.5 sm:py-2 text-slate-200 text-sm min-h-[80px]">
          {value || <span className="text-slate-600">-</span>}
        </div>
      )}
    </div>
  );
};

type SelectFieldProps = {
  label: string;
  value?: string;
  onChange?: (value: string) => void;
  editing: boolean;
  options: { value: string; label: string }[];
};

const SelectField: React.FC<SelectFieldProps> = ({
  label,
  value,
  onChange,
  editing,
  options
}) => {
  return (
    <div>
      <label className="block text-xs sm:text-sm text-slate-400 mb-2">{label}</label>
      {editing ? (
        <select
          value={value || ""}
          onChange={(e) => onChange?.(e.target.value)}
          className="w-full px-3 py-2.5 sm:py-2 bg-slate-800 border border-slate-700 rounded-lg text-slate-100 text-sm focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition-colors"
        >
          {options.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      ) : (
        <div className="px-3 py-2.5 sm:py-2 text-slate-200 text-sm">
          {options.find((o) => o.value === value)?.label || value || <span className="text-slate-600">-</span>}
        </div>
      )}
    </div>
  );
};

export default UserProfile;
