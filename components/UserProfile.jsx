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

// ---------- User Profile Component ----------

export const UserProfile: React.FC<UserProfileProps> = ({
  userId,
  onUpdate
}) => {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [editForm, setEditForm] = useState<Partial<UserProfile>>({});
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
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-slate-400">กำลังโหลด...</div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="text-red-400">ไม่พบข้อมูลผู้ใช้</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100">
      {/* HEADER */}
      <header className="border-b border-slate-800 bg-slate-900/70 backdrop-blur sticky top-0 z-10">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-full bg-emerald-400/20 border border-emerald-400/50 flex items-center justify-center text-sm font-bold text-emerald-300">
              FG
            </div>
              <div>
              <h1 className="text-lg font-semibold">โปรไฟล์ผู้ใช้</h1>
              <p className="text-xs text-slate-400">{profile.worldId}</p>

              {/* New details under world id */}
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
                className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-sm font-medium transition-colors"
              >
                แก้ไข
              </button>
            ) : (
              <>
                <button
                  onClick={handleCancel}
                  className="px-4 py-2 bg-slate-700 hover:bg-slate-600 rounded-lg text-sm font-medium transition-colors"
                >
                  ยกเลิก
                </button>
                <button
                  onClick={handleSave}
                  className="px-4 py-2 bg-emerald-600 hover:bg-emerald-500 rounded-lg text-sm font-medium transition-colors"
                >
                  บันทึก
                </button>
              </>
            )}
          </div>
        </div>
      </header>

      {/* MAIN CONTENT */}
      <main className="max-w-6xl mx-auto px-4 py-6 space-y-6">
        {/* Profile Header Card */}
        <section className="bg-slate-900/60 border border-slate-800 rounded-2xl overflow-hidden shadow-lg">
          <div className="h-32 bg-gradient-to-r from-emerald-600 via-teal-600 to-cyan-600"></div>
          <div className="px-6 pb-6">
            <div className="flex items-end gap-6 -mt-16">
              {/* Avatar */}
              <div className="relative group">
                <div className="w-32 h-32 rounded-full border-4 border-slate-900 bg-slate-800 flex items-center justify-center text-4xl overflow-hidden">
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
                  <div className="absolute bottom-0 right-0 w-10 h-10 bg-emerald-500 rounded-full border-4 border-slate-900 flex items-center justify-center">
                    ✓
                  </div>
                )}
                {/* Upload button overlay */}
                <label className="absolute inset-0 rounded-full cursor-pointer opacity-0 group-hover:opacity-100 transition-opacity">
                  <div className="w-full h-full rounded-full bg-slate-900/70 flex items-center justify-center">
                    <span className="text-white text-sm font-medium">📷 เปลี่ยนรูป</span>
                  </div>
                  <input
                    type="file"
                    accept="image/*"
                    onChange={handleAvatarUpload}
                    className="hidden"
                    disabled={uploadingAvatar}
                  />
                </label>
              </div>

              {/* User Info */}
              <div className="flex-1 pb-2">
                {/* Level removed per UI request */}
                {(profile.firstName || profile.lastName) && (
                  <p className="text-slate-400 mt-1">
                    {profile.firstName} {profile.lastName}
                  </p>
                )}
                <div className="flex items-center gap-4 mt-2 text-sm text-slate-400">
                  {/* Run removed per UI request */}
                  <span>Trust Score: {profile.trustScore.toFixed(1)}</span>
                  <span>•</span>
                  <span>เข้าร่วมเมื่อ {new Date(profile.createdAt).toLocaleDateString('th-TH')}</span>
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column - Stats & ACF Info */}
          <div className="lg:col-span-1 space-y-6">
            {/* Stats Card */}
            <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6 space-y-4">
              <h3 className="text-sm uppercase tracking-wide text-slate-400 font-semibold">สถิติการใช้งาน</h3>

              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-slate-400 text-sm">ยอดขาย</span>
                  <span className="text-emerald-300 font-semibold">{profile.totalSales}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-400 text-sm">ยอดซื้อ</span>
                  <span className="text-cyan-300 font-semibold">{profile.totalPurchases}</span>
                </div>
                <div className="h-px bg-slate-800"></div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-400 text-sm">ระดับการยืนยัน</span>
                  <span className="text-slate-200 font-semibold">
                    {["ไม่ได้ยืนยัน", "โทรศัพท์", "อีเมล", "World ID", "เต็มรูปแบบ"][profile.verificationLevel]}
                  </span>
                </div>
              </div>
            </div>

            {/* ACF Info Card */}
            <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6 space-y-4">
              <h3 className="text-sm uppercase tracking-wide text-slate-400 font-semibold">ข้อมูล ACF</h3>

              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-slate-400 text-sm">จำนวนลูก</span>
                  <span className="text-emerald-300 font-semibold">
                    {profile.childCount} / {profile.maxChildren}
                  </span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-400 text-sm">สถานะรับ ACF</span>
                  <span className={`px-2 py-1 rounded text-xs font-medium ${
                    profile.acfAccepting
                      ? 'bg-emerald-500/20 text-emerald-300'
                      : 'bg-red-500/20 text-red-300'
                  }`}>
                    {profile.acfAccepting ? 'เปิดรับ' : 'ปิดรับ'}
                  </span>
                </div>
                <div className="h-px bg-slate-800"></div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-400 text-sm">Max Network</span>
                  <span className="text-slate-200 font-mono text-sm">{profile.maxNetwork.toLocaleString()}</span>
                </div>
              </div>
            </div>

            {/* Finpoint Card */}
            <div className="bg-gradient-to-br from-emerald-900/40 to-teal-900/40 border border-emerald-700/50 rounded-2xl p-6">
              <h3 className="text-sm uppercase tracking-wide text-emerald-300 font-semibold mb-4">Finpoint</h3>

              <div className="space-y-3">
                <div>
                  <div className="text-slate-400 text-xs mb-1">Own Finpoint</div>
                  <div className="text-2xl font-bold text-emerald-300">
                    {profile.ownFinpoint.toLocaleString()} FP
                  </div>
                </div>
                <div>
                  <div className="text-slate-400 text-xs mb-1">Total Finpoint</div>
                  <div className="text-xl font-semibold text-teal-300">
                    {profile.totalFinpoint.toLocaleString()} FP
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column - Editable Info */}
          <div className="lg:col-span-2 space-y-6">
            {/* Personal Information */}
            <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6">
              <h3 className="text-lg font-semibold mb-6">ข้อมูลส่วนตัว</h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
              </div>

              <div className="mt-4">
                <TextAreaField
                  label="ประวัติส่วนตัว"
                  value={editing ? editForm.bio : profile.bio}
                  onChange={(v) => handleChange("bio", v)}
                  editing={editing}
                  rows={3}
                />
              </div>
            </div>

            {/* Address Information */}
            <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6">
              <h3 className="text-lg font-semibold mb-6">ที่อยู่</h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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

            {/* Preferences */}
            <div className="bg-slate-900/60 border border-slate-800 rounded-2xl p-6">
              <h3 className="text-lg font-semibold mb-6">การตั้งค่า</h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
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
          </div>
        </div>
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
      <label className="block text-sm text-slate-400 mb-2">{label}</label>
      {editing ? (
        <input
          type={type}
          value={value || ""}
          onChange={(e) => onChange?.(e.target.value)}
          className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-slate-100 focus:outline-none focus:border-emerald-500 transition-colors"
        />
      ) : (
        <div className="px-3 py-2 text-slate-200">
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
      <label className="block text-sm text-slate-400 mb-2">{label}</label>
      {editing ? (
        <textarea
          value={value || ""}
          onChange={(e) => onChange?.(e.target.value)}
          rows={rows}
          className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-slate-100 focus:outline-none focus:border-emerald-500 transition-colors resize-none"
        />
      ) : (
        <div className="px-3 py-2 text-slate-200 min-h-[80px]">
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
      <label className="block text-sm text-slate-400 mb-2">{label}</label>
      {editing ? (
        <select
          value={value || ""}
          onChange={(e) => onChange?.(e.target.value)}
          className="w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-slate-100 focus:outline-none focus:border-emerald-500 transition-colors"
        >
          {options.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      ) : (
        <div className="px-3 py-2 text-slate-200">
          {options.find((o) => o.value === value)?.label || value || <span className="text-slate-600">-</span>}
        </div>
      )}
    </div>
  );
};

export default UserProfile;
